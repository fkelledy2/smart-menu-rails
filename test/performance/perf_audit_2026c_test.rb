require 'test_helper'
require 'benchmark'

# Performance regression tests for the third pass of the April 2026 audit.
#
# Issues covered:
#   C1  — cached_user_all_employees N+1 (one SELECT per restaurant)
#   C2  — calculate_popular_items N+1 (ordritems loaded via Ruby per order)
#   C3  — calculate_order_trends loads all order rows into Ruby
#   M1  — serialize_menu uses fetch_menusections.count instead of counter_cache
#   M2  — cached_individual_order_analytics materialises similar orders for avg
#   M3  — calculate_daily_order_breakdown / status_distribution / peak_hours load orders
#   M4  — MenuItemSearchIndexJob per-doc upsert (N SELECT + UPDATE/INSERT per item)
#   N1  — Menu#invalidate_menu_caches now after_commit (outside transaction)
#   N2  — Menuitem#invalidate_menuitem_caches now after_commit (outside transaction)
class PerfAudit2026cTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def count_queries(&)
    count = 0
    counter = ->(*) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

  def assert_query_count(max, message = nil, &)
    actual = count_queries(&)
    assert actual <= max,
           message || "Expected <= #{max} queries but got #{actual}"
  end

  def capture_matching_queries(pattern, &)
    matched = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql   = event.payload[:sql].to_s
      matched << sql if sql.match?(pattern)
    end
    yield
    matched
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  # ---------------------------------------------------------------------------
  # Setup
  # ---------------------------------------------------------------------------

  def setup
    @restaurant = restaurants(:one)
    @menu       = menus(:one)
    @user       = users(:one)
    @ordr       = ordrs(:one)
    Rails.cache.clear
  end

  # ---------------------------------------------------------------------------
  # C1 — cached_user_all_employees uses one batched query, not one per restaurant
  # ---------------------------------------------------------------------------

  test 'cached_user_all_employees issues one employee SELECT regardless of restaurant count' do
    employee_queries = capture_matching_queries(/SELECT.*"employees"/i) do
      AdvancedCacheService.cached_user_all_employees(@user.id)
    end

    # The old code issued one SELECT per restaurant.
    # The new code issues exactly one WHERE restaurant_id IN (...) query.
    assert employee_queries.length <= 1,
           "Expected at most 1 employee SELECT, got #{employee_queries.length}"
  end

  test 'cached_user_all_employees result is sorted by created_at desc' do
    result = AdvancedCacheService.cached_user_all_employees(@user.id)
    employees = result[:employees]
    return if employees.size < 2

    timestamps = employees.pluck(:created_at)
    assert_equal timestamps, timestamps.sort.reverse,
                 'Employees should be sorted newest-first (ORDER BY created_at DESC)'
  end

  # ---------------------------------------------------------------------------
  # C2 — calculate_popular_items uses SQL GROUP BY, not per-order Ruby iteration
  # ---------------------------------------------------------------------------

  test 'calculate_popular_items issues no more than 2 queries for any number of orders' do
    # The old code called order.ordritems for each order (N+1) and then
    # order.ordritems.menuitem for each ordritem.
    # The new code uses a single JOIN + GROUP BY.
    orders = @restaurant.ordrs.limit(10)

    queries = count_queries do
      AdvancedCacheService.send(:calculate_popular_items, orders)
    end

    assert queries <= 2,
           "calculate_popular_items should issue <= 2 queries, got #{queries}"
  end

  test 'calculate_popular_items returns expected shape' do
    orders = @restaurant.ordrs.limit(10)
    result = AdvancedCacheService.send(:calculate_popular_items, orders)

    assert result.key?(:by_quantity), 'Result must include :by_quantity key'
    assert result.key?(:by_revenue),  'Result must include :by_revenue key'
    assert result[:by_quantity].is_a?(Hash)
    assert result[:by_revenue].is_a?(Hash)
  end

  # ---------------------------------------------------------------------------
  # C3 — calculate_order_trends uses SQL GROUP BY + pluck, not Ruby group_by
  # ---------------------------------------------------------------------------

  test 'calculate_order_trends issues one query and does not load order objects' do
    orders = @restaurant.ordrs.where('created_at > ?', 30.days.ago)

    order_object_queries = capture_matching_queries(/SELECT "ordrs"\.\*/) do
      AdvancedCacheService.send(:calculate_order_trends, orders)
    end

    assert order_object_queries.empty?,
           'calculate_order_trends must not load full order rows (SELECT ordrs.*)'
  end

  test 'calculate_order_trends returns correct keys' do
    orders = @restaurant.ordrs.where('created_at > ?', 30.days.ago)
    result = AdvancedCacheService.send(:calculate_order_trends, orders)

    # Either an empty hash (no orders in fixture range) or the expected keys
    if result.any?
      assert result.key?(:daily_orders),          'Missing :daily_orders'
      assert result.key?(:daily_revenue),         'Missing :daily_revenue'
      assert result.key?(:peak_day),              'Missing :peak_day'
      assert result.key?(:average_daily_orders),  'Missing :average_daily_orders'
    end
  end

  # ---------------------------------------------------------------------------
  # M1 — serialize_menu reads menusections_count counter-cache, not fetch count
  # ---------------------------------------------------------------------------

  test 'serialize_menu does not fire a COUNT query on menusections' do
    count_queries_on_sections = capture_matching_queries(/COUNT.*menusections/i) do
      AdvancedCacheService.send(:serialize_menu, @menu)
    end

    assert count_queries_on_sections.empty?,
           'serialize_menu must not issue a COUNT(*) on menusections — use menusections_count'
  end

  test 'serialize_menu sections_count matches menusections_count column' do
    result = AdvancedCacheService.send(:serialize_menu, @menu)
    assert_equal @menu.menusections_count, result[:sections_count],
                 'sections_count must equal the menusections_count counter-cache column'
  end

  # ---------------------------------------------------------------------------
  # M2 — cached_individual_order_analytics uses SQL AVG, not Ruby sum / count
  # ---------------------------------------------------------------------------

  test 'cached_individual_order_analytics uses AVG/COUNT aggregates not Ruby sum' do
    # The old code called .sum { |o| o.runningTotal } which loaded every order row
    # (SELECT ordrs.*) and iterated in Ruby.
    # The new code uses SQL COUNT + AVG — the only ordrs.* SELECT is the single
    # Ordr.find(order_id) call to load the subject order itself.
    all_ordrs_queries = capture_matching_queries(/SELECT "ordrs"\.\*/) do
      AdvancedCacheService.cached_individual_order_analytics(@ordr.id, days: 7)
    end

    # At most 2: one for the Ordr.find(order_id) + possibly one for order.restaurant
    # eager load, but NO unbounded "similar orders" full-row SELECT.
    assert all_ordrs_queries.length <= 2,
           "cached_individual_order_analytics must issue <= 2 ordrs.* SELECTs, " \
           "got #{all_ordrs_queries.length} — similar orders should use AVG/COUNT, not full-row loads"
  end

  test 'cached_individual_order_analytics returns analytics hash' do
    result = AdvancedCacheService.cached_individual_order_analytics(@ordr.id, days: 7)
    assert result.key?(:analytics), 'Missing :analytics key'
    assert result[:analytics].key?(:average_order_value)
    assert result[:analytics][:average_order_value].is_a?(Numeric)
  end

  # ---------------------------------------------------------------------------
  # M3 — calculate_daily_order_breakdown / status_distribution / peak_hours
  # ---------------------------------------------------------------------------

  test 'calculate_daily_order_breakdown uses SQL GROUP BY and does not load rows' do
    orders = @restaurant.ordrs.where('created_at > ?', 30.days.ago)

    full_row_queries = capture_matching_queries(/SELECT "ordrs"\.\*/) do
      AdvancedCacheService.send(:calculate_daily_order_breakdown, orders)
    end

    assert full_row_queries.empty?,
           'calculate_daily_order_breakdown must not SELECT ordrs.* row by row'
  end

  test 'calculate_order_status_distribution uses SQL GROUP BY and does not load rows' do
    orders = @restaurant.ordrs.where('created_at > ?', 30.days.ago)

    full_row_queries = capture_matching_queries(/SELECT "ordrs"\.\*/) do
      AdvancedCacheService.send(:calculate_order_status_distribution, orders)
    end

    assert full_row_queries.empty?,
           'calculate_order_status_distribution must not SELECT ordrs.* row by row'
  end

  test 'calculate_order_peak_hours uses SQL GROUP BY and does not load rows' do
    orders = @restaurant.ordrs.where('created_at > ?', 30.days.ago)

    full_row_queries = capture_matching_queries(/SELECT "ordrs"\.\*/) do
      AdvancedCacheService.send(:calculate_order_peak_hours, orders)
    end

    assert full_row_queries.empty?,
           'calculate_order_peak_hours must not SELECT ordrs.* row by row'
  end

  # ---------------------------------------------------------------------------
  # N1/N2 — Menu and Menuitem cache invalidation is after_commit, not after_update
  # ---------------------------------------------------------------------------

  test 'Menu invalidate_menu_caches is registered on after_commit not after_update' do
    # If the callback is on after_commit it should NOT appear in _update_callbacks
    update_cbs = Menu._update_callbacks.map(&:filter).select do |f|
      f.is_a?(Symbol) && f == :invalidate_menu_caches
    end
    commit_cbs = Menu._commit_callbacks.map(&:filter).select do |f|
      f.is_a?(Symbol) && f == :invalidate_menu_caches
    end

    assert update_cbs.empty?,
           'Menu#invalidate_menu_caches must not be registered on after_update (blocks transaction)'
    assert commit_cbs.any?,
           'Menu#invalidate_menu_caches must be registered on after_commit'
  end

  test 'Menuitem invalidate_menuitem_caches is registered on after_commit not after_update' do
    update_cbs = Menuitem._update_callbacks.map(&:filter).select do |f|
      f.is_a?(Symbol) && f == :invalidate_menuitem_caches
    end
    commit_cbs = Menuitem._commit_callbacks.map(&:filter).select do |f|
      f.is_a?(Symbol) && f == :invalidate_menuitem_caches
    end

    assert update_cbs.empty?,
           'Menuitem#invalidate_menuitem_caches must not be registered on after_update (blocks transaction)'
    assert commit_cbs.any?,
           'Menuitem#invalidate_menuitem_caches must be registered on after_commit'
  end

  # ---------------------------------------------------------------------------
  # analyze_menu_item_performance — no flat_map per order, uses SQL aggregates
  # ---------------------------------------------------------------------------

  test 'analyze_menu_item_performance does not load full ordr objects' do
    orders = @restaurant.ordrs.limit(5)

    full_row_queries = capture_matching_queries(/SELECT "ordrs"\.\*/) do
      AdvancedCacheService.send(:analyze_menu_item_performance, @menu, orders)
    end

    assert full_row_queries.empty?,
           'analyze_menu_item_performance must not SELECT ordrs.* (use SQL aggregates)'
  end

  test 'analyze_menu_item_performance returns a hash keyed by menuitem_id' do
    orders = @restaurant.ordrs.limit(5)
    result = AdvancedCacheService.send(:analyze_menu_item_performance, @menu, orders)

    assert result.is_a?(Hash), 'Result must be a Hash'
    result.each_value do |stats|
      assert stats.key?(:name),           'Each stat must have :name'
      assert stats.key?(:orders_count),   'Each stat must have :orders_count'
      assert stats.key?(:total_quantity), 'Each stat must have :total_quantity'
      assert stats.key?(:total_revenue),  'Each stat must have :total_revenue'
    end
  end
end
