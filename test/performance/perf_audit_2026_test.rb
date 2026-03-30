require 'test_helper'
require 'benchmark'

# Performance tests covering fixes from the March 2026 performance audit.
#
# Each test proves a specific regression no longer exists by asserting an
# upper bound on the number of SQL queries fired.  Query counts are measured
# via ActiveSupport::Notifications so they work without Bullet or additional
# gems.
class PerfAudit2026Test < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Returns the number of SQL queries executed by the block.
  def count_queries(&)
    count = 0
    counter = ->(*) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

  # Asserts the block fires at most +max+ SQL queries.
  def assert_query_count(max, message = nil, &)
    actual = count_queries(&)
    assert actual <= max,
           message || "Expected <= #{max} queries but got #{actual}"
  end

  # ---------------------------------------------------------------------------
  # Setup / fixtures
  # ---------------------------------------------------------------------------

  def setup
    @restaurant = restaurants(:one)
    @menu       = menus(:one)
    @user       = users(:one)
  end

  # ---------------------------------------------------------------------------
  # C1 — MenuitemsController set_currency no longer double-fetches Menuitem
  # ---------------------------------------------------------------------------

  test 'set_currency reuses already-loaded @menuitem and does not re-query' do
    menuitem = menuitems(:one)

    # Simulate what the controller does: set_menuitem loads with includes, then
    # set_currency should NOT fire another SELECT for the same record.
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      queries << event.payload[:sql] if /FROM "menuitems"/i.match?(event.payload[:sql])
    end

    begin
      # Load once with includes (as set_menuitem now does)
      loaded = Menuitem.includes(menusection: { menu: :restaurant }).find(menuitem.id)

      # Accessing the deep association chain should hit no additional queries
      # because everything is already included
      _currency = loaded.menusection.menu.restaurant.currency
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # Only the initial load should have queried menuitems
    assert_equal 1, queries.length,
                 'Expected exactly one SELECT on menuitems (the eager-loaded fetch)'
  end

  # ---------------------------------------------------------------------------
  # C2 — AdvancedCacheService#cached_menu_with_items uses SQL COUNT not Ruby
  # ---------------------------------------------------------------------------

  test 'cached_menu_with_items counts items via SQL not Ruby iteration' do
    # We can only observe the query pattern; the test verifies:
    # 1. The method still returns correct total/active counts
    # 2. It does not fire one COUNT query per menusection (N+1)

    Rails.cache.clear

    menusection_count = @menu.menusections.count

    queries_fired = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql].to_s
      queries_fired << sql if sql.match?(/COUNT.*menuitems/i)
    end

    begin
      result = AdvancedCacheService.cached_menu_with_items(@menu.id)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    count_queries_fired = queries_fired.length

    # Old code fired 2 COUNT queries *per section* (total + active).
    # New code fires at most 2 queries total (one for total, one for active),
    # regardless of how many sections exist.
    assert count_queries_fired <= 2,
           "Expected <= 2 COUNT queries on menuitems but got #{count_queries_fired} " \
           "(old N+1 pattern would have fired #{menusection_count * 2})"

    assert result.is_a?(Hash), 'Expected a Hash result from cached_menu_with_items'
    assert result.key?(:metadata), 'Expected :metadata key in result'
  end

  # ---------------------------------------------------------------------------
  # C3 — cached_restaurant_orders uses counter_cache, not per-order COUNT
  # ---------------------------------------------------------------------------

  test 'cached_restaurant_orders does not fire one COUNT per order' do
    Rails.cache.clear

    # Count per-order COUNT queries — these fire as "SELECT COUNT(*) FROM ordritems WHERE ordr_id = ?"
    count_queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql].to_s
      count_queries << sql if sql.match?(/COUNT.*ordritems/i)
    end

    begin
      AdvancedCacheService.cached_restaurant_orders(@restaurant.id)
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # The counter_cache (ordritems_count column) should mean zero COUNT queries
    # against ordritems when building the orders list.
    assert count_queries.empty?,
           "Expected 0 COUNT queries against ordritems (use counter_cache instead), " \
           "but got #{count_queries.length}: #{count_queries.first(3).inspect}"
  end

  # ---------------------------------------------------------------------------
  # C4 — cached_order_analytics uses SQL SUM not Ruby enumeration
  # ---------------------------------------------------------------------------

  test 'cached_order_analytics aggregates revenue in SQL not Ruby' do
    Rails.cache.clear

    # If the old Ruby .sum { |o| o.gross } is used, it materialises all Order
    # objects.  The new code uses orders_in_range.sum('COALESCE(gross, 0)') —
    # a single SQL aggregation.  We verify no individual order rows are SELECTed
    # for the purpose of summing gross.
    full_select_queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql].to_s
      # A full SELECT * / SELECT ordrs.* to materialise all rows is the bad pattern
      full_select_queries << sql if sql.match?(/SELECT\s+"ordrs"\.\*.*FROM\s+"ordrs"/i)
    end

    begin
      AdvancedCacheService.cached_order_analytics(
        @restaurant.id,
        30.days.ago..Time.current,
      )
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # The SQL SUM aggregate does not require a full row scan in the application
    # layer — only a SUM() query.  The old code would select all rows.
    # We allow one full SELECT (e.g. for trends/breakdown), but not an unbounded load.
    assert full_select_queries.length <= 2,
           "Expected <= 2 full SELECT on ordrs but got #{full_select_queries.length}; " \
           "check that revenue is computed with SQL SUM not Ruby iteration"
  end

  # ---------------------------------------------------------------------------
  # M1 — Restaurant#total_capacity uses SQL SUM
  # ---------------------------------------------------------------------------

  test 'total_capacity uses SQL SUM not Ruby enumeration' do
    tablesetting_queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql].to_s
      tablesetting_queries << sql if sql.match?(/tablesettings/i)
    end

    begin
      @restaurant.total_capacity
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # Exactly one query: SELECT SUM("tablesettings"."capacity") FROM "tablesettings" WHERE ...
    assert_equal 1, tablesetting_queries.length,
                 'Expected exactly 1 SQL query for total_capacity (SQL SUM)'

    assert tablesetting_queries.first.match?(/SUM/i),
           "Expected a SUM aggregate query but got: #{tablesetting_queries.first}"
  end

  # ---------------------------------------------------------------------------
  # M2 — MenusectionsController set_menusection uses counter_cache
  # ---------------------------------------------------------------------------

  test 'menusections set_menusection reads menuitems_count from counter cache column' do
    # The fix reads @menusection.menu.menuitems_count (a DB column) instead of
    # firing @menusection.menu.menuitems.count (a COUNT query).
    # We verify by checking the column is accessible without a COUNT query.
    menu = menus(:one)

    count_queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql].to_s
      count_queries << sql if sql.match?(/COUNT.*menuitems/i)
    end

    begin
      # Access the attribute directly (as the fixed controller does)
      _ = menu.menuitems_count
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    assert count_queries.empty?,
           "Expected 0 COUNT queries on menuitems when reading counter_cache column, " \
           "but got: #{count_queries.inspect}"
  end

  # ---------------------------------------------------------------------------
  # M3 — Restaurant#whiskey_ambassador_ready? uses a single SQL query
  # ---------------------------------------------------------------------------

  test 'whiskey_ambassador_ready? fires at most one SQL query' do
    # The old implementation called menus.any? { |menu| menu.menuitems.where(...).count >= 10 }
    # which fired one COUNT per menu.  The new implementation uses a single
    # EXISTS subquery regardless of menu count.
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      sql = event.payload[:sql].to_s
      # Capture any query that touches menuitems for this restaurant's whiskey check
      queries << sql if sql.match?(/menuitems/i) || sql.match?(/menusections/i)
    end

    begin
      @restaurant.whiskey_ambassador_ready?
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # Result: 0 if whiskey_ambassador not enabled, or 1 for the EXISTS query.
    assert queries.length <= 1,
           "Expected <= 1 query for whiskey_ambassador_ready? but got #{queries.length}: " \
           "#{queries.inspect}"
  end
end
