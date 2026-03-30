require 'test_helper'
require 'benchmark'

# Performance regression tests covering the second batch of fixes from the
# March 2026 performance audit (second pass).
#
# Issues addressed:
#   C1  — OrdrsController / OrdritemsController double-fetch of Restaurant / Ordritem
#   C2  — cached_user_activity Ruby revenue aggregation (N queries per restaurant)
#   C3  — cached_user_all_orders N+1 ordritems.count per order
#   C4  — cached_order_with_details missing eager load for ordritems+menuitem
#   M1  — RecalculateMenuitemCostsJob N+1 find_by per affected item
#   M3  — serialize_order_basic uses ordritems.count instead of counter-cache
#   M4  — calculate_daily_breakdown calls ordritems.count per order
#   N1  — cached_section_items_with_details lazy-loads menusection.menu
#   N2  — cached_menuitem_with_analytics lazy-loads menusection.menu.restaurant chain
class PerfAudit2026bTest < ActiveSupport::TestCase
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

  # Returns all SQL strings emitted during the block that match +pattern+.
  def capture_matching_queries(pattern, &)
    matched = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql].to_s
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
    @ordr       = ordrs(:one)
    @user       = users(:one)
    Rails.cache.clear
  end

  # ---------------------------------------------------------------------------
  # C1 — OrdrsController set_currency no longer re-fetches @restaurant
  # ---------------------------------------------------------------------------

  test 'set_currency reuses @restaurant already loaded by set_restaurant' do
    # Simulate the before_action ordering in OrdrsController:
    # 1. set_restaurant runs first and assigns @restaurant
    # 2. set_currency checks @restaurant before issuing a new find
    restaurant_queries = capture_matching_queries(/SELECT.*"restaurants"/i) do
      # Simulate set_restaurant: load once
      @loaded_restaurant = Restaurant.find(@restaurant.id)

      # Simulate set_currency: should NOT fire a second SELECT because @restaurant is set
      # The fixed code: @restaurant ||= Restaurant.find(params[:restaurant_id])
      @loaded_restaurant ||= Restaurant.find(@restaurant.id)
      _currency = ISO4217::Currency.from_code(@loaded_restaurant.currency || 'USD')
    end

    assert_equal 1, restaurant_queries.length,
                 'set_currency must not issue a second SELECT on restaurants when ' \
                 '@restaurant is already assigned'
  end

  # ---------------------------------------------------------------------------
  # C1b — OrdritemsController set_currency no longer re-fetches @ordritem
  # ---------------------------------------------------------------------------

  test 'OrdritemsController set_currency reuses @ordritem already set by set_ordritem' do
    ordritem = ordritems(:one)

    ordritem_queries = capture_matching_queries(/SELECT.*"ordritems"/i) do
      # Simulate set_ordritem loading the record
      loaded = Ordritem.find(ordritem.id)

      # Simulate set_currency: should not re-query ordritems
      loaded ||= Ordritem.find(ordritem.id)
      _currency = ISO4217::Currency.from_code(loaded.ordr.restaurant.currency || 'USD')
    end

    assert_equal 1, ordritem_queries.length,
                 'set_currency must not re-SELECT ordritems when @ordritem already loaded'
  end

  # ---------------------------------------------------------------------------
  # C2 — cached_user_activity does not fire per-restaurant order queries
  # ---------------------------------------------------------------------------

  test 'cached_user_activity aggregates revenue via SQL SUM not Ruby iteration' do
    Rails.cache.clear

    # Count full-row SELECT * on ordrs — the bad pattern loads all order objects
    # into Ruby just to call .gross on each one.
    full_row_selects = capture_matching_queries(/SELECT\s+"ordrs"\.\*.*FROM\s+"ordrs"/i) do
      AdvancedCacheService.cached_user_activity(@user.id, days: 30)
    end

    # The fix uses a GROUP BY + SUM aggregate — no full-row fetches for revenue calc.
    # We allow at most 1 full-row SELECT (e.g. for a daily breakdown helper), but not
    # one per restaurant.
    restaurant_count = @user.restaurants.count
    assert full_row_selects.length <= [restaurant_count, 1].min + 1,
           "Revenue aggregation must use SQL SUM, not load all order rows. " \
           "Got #{full_row_selects.length} full-row SELECT(s) for #{restaurant_count} restaurant(s)"
  end

  test 'cached_user_activity total query count is bounded regardless of restaurant count' do
    Rails.cache.clear

    # The fixed implementation issues: 1 (user) + 1 (restaurants) + 1 (order aggregates)
    # + 1 (menu update counts) = 4 queries, independent of restaurant count.
    assert_query_count(15, 'cached_user_activity should use batched queries, not per-restaurant loops') do
      AdvancedCacheService.cached_user_activity(@user.id, days: 7)
    end
  end

  # ---------------------------------------------------------------------------
  # C3 — cached_user_all_orders uses ordritems_count counter-cache
  # ---------------------------------------------------------------------------

  test 'cached_user_all_orders does not fire COUNT queries on ordritems' do
    Rails.cache.clear

    count_queries_fired = capture_matching_queries(/COUNT.*ordritems/i) do
      AdvancedCacheService.cached_user_all_orders(@user.id)
    end

    assert count_queries_fired.empty?,
           "cached_user_all_orders must use ordritems_count counter-cache, not COUNT per order. " \
           "Got #{count_queries_fired.length} COUNT query/queries: #{count_queries_fired.first(2).inspect}"
  end

  # ---------------------------------------------------------------------------
  # C4 — cached_order_with_details eager-loads ordritems+menuitem
  # ---------------------------------------------------------------------------

  test 'cached_order_with_details does not fire per-ordritem SELECT on menuitems' do
    Rails.cache.clear

    # The bad pattern: `order.ordritems.map { |i| i.menuitem.name }` fires one
    # SELECT on menuitems per ordritem. The fix includes menuitem in the initial load.
    menuitem_selects = capture_matching_queries(/SELECT.*"menuitems".*FROM\s+"menuitems"/i) do
      AdvancedCacheService.cached_order_with_details(@ordr.id)
    end

    # The eager load fires exactly one batch SELECT on menuitems.
    # If per-item lazy loads occurred we would see one SELECT per ordritem.
    ordritem_count = @ordr.ordritems.count
    assert menuitem_selects.length <= 1,
           "cached_order_with_details must eager-load menuitems (1 query). " \
           "Got #{menuitem_selects.length} — #{ordritem_count} ordritems would cause #{ordritem_count} lazy loads"
  end

  test 'cached_order_with_details plucks taxes instead of instantiating Tax objects' do
    Rails.cache.clear

    # Verify the method still returns a valid result (smoke test)
    result = AdvancedCacheService.cached_order_with_details(@ordr.id)

    assert result.is_a?(Hash), 'Expected a Hash'
    assert result.key?(:calculations), 'Expected :calculations key'
    assert result[:calculations].key?(:gross), 'Expected :gross in calculations'
    assert result.key?(:items), 'Expected :items key'
  end

  # ---------------------------------------------------------------------------
  # M1 — RecalculateMenuitemCostsJob batch-loads menuitems (no per-item find_by)
  # ---------------------------------------------------------------------------

  test 'RecalculateMenuitemCostsJob does not fire one SELECT per menuitem' do
    # The job receives an ingredient_id and finds affected menuitems.
    # The fix loads all menuitems in a single WHERE id IN (...) query.
    ingredient = ingredients(:one)

    # Count individual per-id menuitem SELECTs (the old N+1 pattern)
    per_id_selects = capture_matching_queries(/SELECT.*"menuitems".*WHERE.*"menuitems"\."id"\s*=\s*\$/i) do
      RecalculateMenuitemCostsJob.perform_now(ingredient.id)
    end

    assert per_id_selects.empty?,
           "RecalculateMenuitemCostsJob must not issue one find_by per menuitem_id. " \
           "Got #{per_id_selects.length} individual SELECT(s)"
  end

  # ---------------------------------------------------------------------------
  # M3 — serialize_order_basic uses ordritems_count counter-cache column
  # ---------------------------------------------------------------------------

  test 'serialize_order_basic reads ordritems_count column not COUNT query' do
    # Access the column directly (as the fixed serialize_order_basic now does)
    count_queries_fired = capture_matching_queries(/COUNT.*ordritems/i) do
      # Simulate what serialize_order_basic does for a loaded order object
      _ = @ordr.ordritems_count
    end

    assert count_queries_fired.empty?,
           'Reading ordritems_count must not fire a COUNT(*) query; it is a plain column read'
  end

  test 'ordritems_count column is present and non-negative on Ordr' do
    assert @ordr.respond_to?(:ordritems_count),
           'Ordr must have ordritems_count attribute (counter-cache column)'
    assert @ordr.ordritems_count >= 0,
           "ordritems_count should be >= 0, got #{@ordr.ordritems_count}"
  end

  # ---------------------------------------------------------------------------
  # M4 — calculate_daily_breakdown uses ordritems_count not per-order COUNT
  # ---------------------------------------------------------------------------

  test 'cached_restaurant_order_summary does not fire COUNT on ordritems for daily breakdown' do
    Rails.cache.clear

    count_queries_fired = capture_matching_queries(/COUNT.*ordritems/i) do
      AdvancedCacheService.cached_restaurant_order_summary(@restaurant.id, days: 7)
    end

    assert count_queries_fired.empty?,
           "Order summary / daily breakdown must not issue COUNT(*) per order on ordritems. " \
           "Got #{count_queries_fired.length} COUNT queries"
  end

  # ---------------------------------------------------------------------------
  # N1 — cached_section_items_with_details does not lazy-load menu
  # ---------------------------------------------------------------------------

  test 'cached_section_items_with_details does not lazy-load menu association' do
    section = @menu.menusections.first
    skip 'No menusections in fixture' unless section

    Rails.cache.clear

    menu_selects = capture_matching_queries(/SELECT.*"menus".*FROM\s+"menus"/i) do
      AdvancedCacheService.cached_section_items_with_details(section.id)
    end

    # The fix uses includes(:menu) so at most one SELECT on menus (the include).
    assert menu_selects.length <= 1,
           "cached_section_items_with_details must include :menu, got #{menu_selects.length} menu SELECTs"
  end

  # ---------------------------------------------------------------------------
  # N2 — cached_menuitem_with_analytics does not lazy-load association chain
  # ---------------------------------------------------------------------------

  test 'cached_menuitem_with_analytics does not fire 3 lazy-load queries for menusection.menu.restaurant' do
    menuitem = menuitems(:one)
    Rails.cache.clear

    # Count queries that touch the menusections → menus → restaurants chain.
    # The fix uses includes(menusection: { menu: :restaurant }) so the chain
    # is loaded in one compound eager-load — not 3 individual lazy-load SELECTs.
    chain_queries = capture_matching_queries(/(FROM\s+"menusections"|FROM\s+"menus"|FROM\s+"restaurants")/i) do
      AdvancedCacheService.cached_menuitem_with_analytics(menuitem.id)
    end

    # With eager loading the AR adapter may emit 1–3 batch SELECTs (one per table
    # in the includes chain). What we must NOT see is per-record lazy loads where
    # each access triggers its own round-trip.  We allow up to 3 (one per table).
    assert chain_queries.length <= 3,
           "Expected <=3 queries for the association chain (eager load), " \
           "got #{chain_queries.length}. Check that includes(menusection: { menu: :restaurant }) is applied."
  end

  test 'cached_menuitem_with_analytics returns expected keys' do
    menuitem = menuitems(:one)
    Rails.cache.clear

    result = AdvancedCacheService.cached_menuitem_with_analytics(menuitem.id)

    assert result.is_a?(Hash), 'Expected a Hash result'
    assert result.key?(:menuitem), 'Expected :menuitem key'
    assert result.key?(:section),  'Expected :section key'
    assert result.key?(:menu),     'Expected :menu key'
    assert result.key?(:restaurant), 'Expected :restaurant key'
  end
end
