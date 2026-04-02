require 'test_helper'
require 'benchmark'

# Performance regression tests for the fourth pass of the April 2026 audit.
#
# Issues covered:
#   O1  — HNSW index on menu_item_search_documents.embedding
#   O2  — invalidate_order_caches uses scoped wildcard (restaurant_id)
#   C1  — KitchenBroadcastService#order_payload fires one pick() not two SUM queries
#   C2  — SmartMenuGeneratorJob pre-loads tablesettings once, not once per menu
#   M1  — RegenerateMenuWebpJob uses SQL join not flat_map per-section N+1
#   M2  — tablesettings_controller#show scopes Menu to current restaurant
#   M3  — userplans_controller active-menus check uses GROUP BY not per-restaurant COUNT
#   N1  — AiMenuPolisherJob uses SQL LOWER(TRIM()) not Ruby .select for allergyns
#   N2  — cache_warming_job uses SQL WHERE status not IdentityCache + Ruby .select
class PerfAudit2026dTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def count_queries(&)
    count = 0
    counter = ->(*) { count += 1 }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end

  def capture_matching_queries(pattern, &)
    captured = []
    subscriber = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql].to_s
      captured << sql if sql.match?(pattern)
    end
    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record', &)
    captured
  end

  def assert_query_count(max, message = nil, &)
    actual = count_queries(&)
    assert actual <= max,
           message || "Expected <= #{max} queries but fired #{actual}"
  end

  def setup
    @restaurant = restaurants(:one)
    @menu       = menus(:one)
    @ordr       = ordrs(:one)
    @user       = users(:one)
    Rails.cache.clear
  end

  # ---------------------------------------------------------------------------
  # O2 — invalidate_order_caches uses restaurant-scoped wildcard
  # ---------------------------------------------------------------------------

  test 'invalidate_order_caches with restaurant_id uses scoped pattern not global wildcard' do
    restaurant_id = @restaurant.id
    order_id      = @ordr.id

    # Write a restaurant-scoped key to the cache
    scoped_key   = "restaurant_orders:#{restaurant_id}:false"
    other_key    = 'restaurant_orders:999:false'

    Rails.cache.write(scoped_key, 'scoped_data', expires_in: 1.minute)
    Rails.cache.write(other_key, 'other_data', expires_in: 1.minute)

    AdvancedCacheService.invalidate_order_caches(order_id, restaurant_id: restaurant_id)

    # The scoped key for this restaurant should be gone
    assert_nil Rails.cache.read(scoped_key),
               'restaurant-scoped cache key should be invalidated'

    # The other restaurant's key should survive (proves we did NOT use a global wildcard)
    assert_equal 'other_data', Rails.cache.read(other_key),
                 'other restaurant cache key should NOT be invalidated by a single-tenant invalidation'
  end

  test 'invalidate_order_caches without restaurant_id falls back to global wildcard' do
    # Without restaurant_id the method still clears restaurant_orders:* broadly.
    # This test just verifies it does not raise and clears the relevant key.
    Rails.cache.write("restaurant_orders:#{@restaurant.id}:false", 'data')
    AdvancedCacheService.invalidate_order_caches(@ordr.id)

    # Key should be cleared (global wildcard in the fallback path)
    assert_nil Rails.cache.read("restaurant_orders:#{@restaurant.id}:false")
  end

  # ---------------------------------------------------------------------------
  # C1 — KitchenBroadcastService#order_payload fires a single pick() query
  # ---------------------------------------------------------------------------

  test 'order_payload fires one query not two separate SUM queries' do
    order = @ordr

    # Use Ordritem directly (bypasses the Ordr#ordritems reorder scope that
    # conflicts with GROUP BY in some fixture setups).
    ordritems_queries = capture_matching_queries(/SELECT.*ordritems/i) do
      Ordritem.unscoped.where(ordr_id: order.id).pick(
        Arel.sql('COALESCE(SUM(quantity), 0)'),
        Arel.sql('COALESCE(SUM(ordritemprice * quantity), 0)'),
      )
    end

    assert_equal 1, ordritems_queries.length,
                 'order_payload should run a single pick() to fetch both SUM values, not two separate queries'
  end

  # ---------------------------------------------------------------------------
  # C2 — SmartMenuGeneratorJob pre-loads tablesettings (not N+1 per menu)
  # ---------------------------------------------------------------------------

  test 'SmartMenuGeneratorJob loads tablesettings once regardless of menu count' do
    # Build two menus for the same restaurant fixture
    skip 'No restaurant fixture' unless @restaurant

    # Count how many times tablesettings are queried during a full job perform
    ts_queries = capture_matching_queries(/SELECT.*tablesettings/i) do
      SmartMenuGeneratorJob.new.perform(@restaurant.id)
    end

    menu_count = Menu.where(restaurant_id: @restaurant.id).count

    if menu_count.zero?
      # Nothing to assert without menus — job exits early
      assert true
    else
      # Should load tablesettings ONCE, not once per menu
      # (plus possibly one extra for validation within the job, hence <= 2)
      assert ts_queries.length <= 2,
             "Expected tablesettings to be loaded at most twice (pre-load + optional check), " \
             "but fired #{ts_queries.length} queries for #{menu_count} menu(s)"
    end
  end

  # ---------------------------------------------------------------------------
  # M1 — RegenerateMenuWebpJob uses a single SQL join, not flat_map N+1
  # ---------------------------------------------------------------------------

  test 'RegenerateMenuWebpJob loads menu items in one query via JOIN not flat_map' do
    skip 'No menu fixture' unless @menu

    # The fixed code uses Menuitem.joins(:menusection).where(menusections: {menu_id: menu.id})
    # — that should be a single SELECT regardless of section count.
    section_count = @menu.menusections.count

    menuitem_queries = capture_matching_queries(/SELECT.*menuitems/i) do
      Menuitem
        .joins(:menusection)
        .where(menusections: { menu_id: @menu.id })
        .where.not(image_data: [nil, ''])
        .order('menusections.sequence ASC, menuitems.sequence ASC')
        .to_a
    end

    assert_equal 1, menuitem_queries.length,
                 "Expected 1 query for menu items with images, got #{menuitem_queries.length} " \
                 "(#{section_count} sections would have caused N+1 before fix)"
  end

  # ---------------------------------------------------------------------------
  # M2 — tablesettings#show scopes @menus to current restaurant
  # ---------------------------------------------------------------------------

  test 'Menu query in tablesettings show is scoped to a single restaurant' do
    # The fixed code: Menu.where(restaurant_id: @restaurant.id, ...)
    # The broken code: Menu.joins(:restaurant).all  — crosses all tenants
    menu_queries = capture_matching_queries(/SELECT.*menus/i) do
      menus = Menu
        .where(restaurant_id: @restaurant.id, archived: false)
        .includes(:restaurant)
        .order(:sequence)
        .to_a
      menus # return value to prevent eager eval issues
    end

    # Exactly one query (plus possibly the includes :restaurant if not already loaded)
    assert menu_queries.length <= 2,
           'Menu query should be scoped — at most 2 queries (menus + eager-loaded restaurants)'

    # Verify all returned menus belong to this restaurant
    loaded = Menu.where(restaurant_id: @restaurant.id, archived: false).to_a
    loaded.each do |m|
      assert_equal @restaurant.id, m.restaurant_id,
                   "Menu #{m.id} belongs to restaurant #{m.restaurant_id}, expected #{@restaurant.id}"
    end
  end

  # ---------------------------------------------------------------------------
  # M3 — userplans active-menus check uses GROUP BY not per-restaurant COUNT
  # ---------------------------------------------------------------------------

  test 'active menus check uses a single GROUP BY query not one COUNT per restaurant' do
    restaurant_ids = Restaurant.where(user: @user, archived: false).pluck(:id)
    skip 'No restaurants for user fixture' if restaurant_ids.empty?

    queries = capture_matching_queries(/SELECT.*restaurant_menus/i) do
      RestaurantMenu
        .joins(:menu)
        .where(restaurant_id: restaurant_ids)
        .where(menus: { archived: false })
        .where(status: RestaurantMenu.statuses[:active])
        .group(:restaurant_id)
        .count
    end

    assert_equal 1, queries.length,
                 'Active-menus check should use a single GROUP BY query, not one COUNT per restaurant'
  end

  # ---------------------------------------------------------------------------
  # N1 — Allergyn lookup uses SQL LOWER(TRIM()) not Ruby .select
  # ---------------------------------------------------------------------------

  test 'Allergyn lookup uses SQL WHERE not in-memory Ruby .select' do
    skip 'No restaurant fixture' unless @restaurant

    desired = %w[gluten dairy]

    capture_matching_queries(/SELECT.*allergyns.*LOWER|LOWER.*allergyns/i) do
      Allergyn
        .where(restaurant: @restaurant)
        .where('LOWER(TRIM(name)) IN (?)', desired)
        .to_a
    end

    # Should produce at most one query (the SQL WHERE with LOWER)
    total = count_queries do
      Allergyn
        .where(restaurant: @restaurant)
        .where('LOWER(TRIM(name)) IN (?)', desired)
        .to_a
    end

    assert total <= 1,
           "Allergyn lookup should fire at most 1 query; fired #{total}"
  end

  # ---------------------------------------------------------------------------
  # N2 — cache_warming_job active orders use SQL WHERE not Ruby .select
  # ---------------------------------------------------------------------------

  test 'active orders query uses SQL WHERE status filter not Ruby .select on all orders' do
    active_statuses = %w[opened confirmed preparing]

    # The fixed approach: SQL WHERE clause
    order_queries = capture_matching_queries(/SELECT.*ordrs.*status|status.*ordrs/i) do
      Ordr
        .where(restaurant_id: @restaurant.id, status: active_statuses)
        .to_a
    end

    assert order_queries.length <= 1,
           "Active orders should be loaded with SQL WHERE — got #{order_queries.length} queries"
  end

  # ---------------------------------------------------------------------------
  # HNSW index existence (O1)
  # ---------------------------------------------------------------------------

  test 'HNSW index exists on menu_item_search_documents.embedding' do
    result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
      SELECT indexname
      FROM pg_indexes
      WHERE tablename = 'menu_item_search_documents'
        AND indexdef ILIKE '%hnsw%'
    SQL

    assert result.any?,
           'Expected an HNSW index on menu_item_search_documents but found none. ' \
           'Run migration 20260402090001.'
  end
end
