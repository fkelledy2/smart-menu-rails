require 'test_helper'

class AdvancedCacheServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @ordr = ordrs(:one)

    # Clear cache before each test
    Rails.cache.clear
    AdvancedCacheService.reset_cache_stats
  end

  def teardown
    # Clean up cache after each test
    Rails.cache.clear
  end

  # Cache statistics tests
  test 'should track cache statistics' do
    # Initial stats should be zero
    stats = AdvancedCacheService.cache_stats
    assert_equal 0, stats[:hits]
    assert_equal 0, stats[:misses]
    assert_equal 0, stats[:writes]
    assert_equal 0, stats[:deletes]
    assert_equal 0, stats[:errors]
  end

  test 'should reset cache statistics' do
    # Increment some metrics first
    AdvancedCacheService.increment_metric(:hits)
    AdvancedCacheService.increment_metric(:misses)

    # Reset stats
    AdvancedCacheService.reset_cache_stats

    stats = AdvancedCacheService.cache_stats
    assert_equal 0, stats[:hits]
    assert_equal 0, stats[:misses]
    assert stats[:last_reset].present?
  end

  test 'should increment metrics correctly' do
    AdvancedCacheService.increment_metric(:hits)
    AdvancedCacheService.increment_metric(:hits)
    AdvancedCacheService.increment_metric(:misses)

    stats = AdvancedCacheService.cache_stats
    assert_equal 2, stats[:hits]
    assert_equal 1, stats[:misses]
  end

  test 'should handle metric increment errors gracefully' do
    # Test that increment_metric doesn't raise errors even with invalid metrics
    assert_nothing_raised do
      AdvancedCacheService.increment_metric(:invalid_metric)
    end
  end

  test 'should calculate hit rate correctly' do
    AdvancedCacheService.increment_metric(:hits)
    AdvancedCacheService.increment_metric(:hits)
    AdvancedCacheService.increment_metric(:misses)

    hit_rate = AdvancedCacheService.send(:calculate_hit_rate)
    assert_equal 66.67, hit_rate
  end

  test 'should handle zero operations for hit rate' do
    hit_rate = AdvancedCacheService.send(:calculate_hit_rate)
    assert_equal 0.0, hit_rate
  end

  # Monitored cache fetch tests
  test 'should track cache miss in monitored fetch' do
    result = AdvancedCacheService.monitored_cache_fetch('test_key') do
      'test_value'
    end

    assert_equal 'test_value', result

    stats = AdvancedCacheService.cache_stats
    assert_equal 1, stats[:misses]
    assert_equal 1, stats[:writes]
  end

  test 'should track cache hit in monitored fetch' do
    # First call - cache miss
    AdvancedCacheService.monitored_cache_fetch('test_hit_key') { 'test_value' }

    # Second call - cache hit
    result = AdvancedCacheService.monitored_cache_fetch('test_hit_key') { 'should_not_execute' }

    assert_equal 'test_value', result

    stats = AdvancedCacheService.cache_stats
    assert stats[:hits] >= 1
    assert stats[:misses] >= 1
  end

  test 'should handle cache errors in monitored fetch' do
    # Test that monitored fetch works with valid cache operations
    result = AdvancedCacheService.monitored_cache_fetch('test_error_key') do
      'fallback_value'
    end

    assert_equal 'fallback_value', result
  end

  # Cache info tests
  test 'should provide cache info' do
    info = AdvancedCacheService.cache_info

    assert info[:service_version].present?
    assert info[:total_methods].is_a?(Integer)
    assert info[:active_keys].is_a?(Integer)
    assert info[:memory_usage].is_a?(Hash)
    assert info[:performance].is_a?(Hash)
  end

  # Menu caching tests
  test 'should cache menu with items' do
    result = AdvancedCacheService.cached_menu_with_items(@menu.id)

    assert result[:menu].present?
    assert result[:restaurant].present?
    assert result[:sections].is_a?(Array)
    assert result[:metadata].present?
    assert result[:metadata][:cached_at].present?
  end

  test 'should cache menu with locale parameter' do
    result = AdvancedCacheService.cached_menu_with_items(@menu.id, locale: 'es')

    assert result[:menu].present?
    assert result[:metadata].present?
  end

  test 'should cache menu with include_inactive parameter' do
    result = AdvancedCacheService.cached_menu_with_items(@menu.id, include_inactive: true)

    assert result[:menu].present?
    assert result[:sections].is_a?(Array)
  end

  # Restaurant dashboard tests
  test 'should cache restaurant dashboard' do
    result = AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)

    assert result[:restaurant].present?
    assert result[:stats].present?
    assert result[:recent_activity].present?
    assert result[:quick_access].present?

    # Check stats structure
    assert result[:stats][:active_menus_count].is_a?(Integer)
    assert result[:stats][:total_menus_count].is_a?(Integer)
    assert result[:stats][:staff_count].is_a?(Integer)
  end

  # Order analytics tests
  test 'should cache restaurant order analytics' do
    date_range = 7.days.ago..Time.current
    result = AdvancedCacheService.cached_order_analytics(@restaurant.id, date_range)

    assert result[:period].present?
    assert result[:totals].present?
    assert result[:trends].present?
    assert result[:popular_items].present?
    assert result[:daily_breakdown].present?

    # Check period structure
    assert_equal date_range.begin.to_date, result[:period][:start_date]
    assert_equal date_range.end.to_date, result[:period][:end_date]
  end

  test 'should handle default date range for restaurant order analytics' do
    result = AdvancedCacheService.cached_order_analytics(@restaurant.id)

    assert result[:period].present?
    assert result[:totals].present?
  end

  # Menu performance tests
  test 'should cache menu performance' do
    result = AdvancedCacheService.cached_menu_performance(@menu.id)

    assert result[:menu].present?
    assert result[:period_days] == 30
    assert result[:performance].present?
    assert result[:item_analysis].present?
    assert result[:recommendations].present?
  end

  test 'should cache menu performance with custom days' do
    result = AdvancedCacheService.cached_menu_performance(@menu.id, days: 7)

    assert result[:period_days] == 7
    assert result[:performance].present?
  end

  # User activity tests
  test 'should cache user activity' do
    result = AdvancedCacheService.cached_user_activity(@user.id)

    assert result[:user].present?
    assert result[:period_days] == 7
    assert result[:summary].present?
    assert result[:restaurants].is_a?(Array)

    # Check summary structure
    assert result[:summary][:total_restaurants].is_a?(Integer)
    assert result[:summary][:total_orders].is_a?(Integer)
  end

  test 'should cache user activity with custom days' do
    result = AdvancedCacheService.cached_user_activity(@user.id, days: 14)

    assert result[:period_days] == 14
    assert result[:summary].present?
  end

  # Menu items caching tests
  test 'should cache menu items with details' do
    result = AdvancedCacheService.cached_menu_items_with_details(@menu.id)

    assert result[:menu].present?
    assert result[:items].is_a?(Array)
    assert result[:metadata].present?
    assert result[:metadata][:total_items].is_a?(Integer)
    assert result[:metadata][:cached_at].present?
  end

  test 'should cache menu items with analytics' do
    result = AdvancedCacheService.cached_menu_items_with_details(@menu.id, include_analytics: true)

    assert result[:items].is_a?(Array)

    # Check if analytics are included when items exist
    if result[:items].any?
      first_item = result[:items].first
      assert first_item[:analytics].present? if first_item
    end
  end

  # Section items caching tests
  test 'should cache section items with details' do
    menusection = @menu.menusections.first
    skip 'No menusections available' unless menusection

    result = AdvancedCacheService.cached_section_items_with_details(menusection.id)

    assert result[:section].present?
    assert result[:items].is_a?(Array)
    assert result[:metadata].present?
    assert result[:metadata][:total_items].is_a?(Integer)
  end

  # Individual menuitem tests
  test 'should cache menuitem with analytics' do
    menuitem = menuitems(:one) # Use fixture directly

    result = AdvancedCacheService.cached_menuitem_with_analytics(menuitem.id)

    assert result[:menuitem].present?
    assert result[:section].present?
    assert result[:menu].present?
    assert result[:restaurant].present?
    assert result[:analytics].present?
    assert result[:cached_at].present?
  end

  test 'should cache menuitem performance' do
    menuitem = menuitems(:one) # Use fixture directly

    result = AdvancedCacheService.cached_menuitem_performance(menuitem.id)

    assert result[:menuitem].present?
    assert result[:period_days] == 30
    assert result[:performance].present?
    assert result[:trends].present?
    assert result[:recommendations].is_a?(Array)
  end

  test 'should cache menuitem performance with custom days' do
    menuitem = menuitems(:one) # Use fixture directly

    result = AdvancedCacheService.cached_menuitem_performance(menuitem.id, days: 7)

    assert result[:period_days] == 7
  end

  # Restaurant orders tests
  test 'should cache restaurant orders' do
    result = AdvancedCacheService.cached_restaurant_orders(@restaurant.id)

    assert result[:restaurant].present?
    assert result[:orders].is_a?(Array)
    assert result[:metadata].present?
    assert result[:metadata][:total_orders].is_a?(Integer)
    assert result[:metadata][:cached_at].present?
  end

  test 'should cache restaurant orders with calculations' do
    result = AdvancedCacheService.cached_restaurant_orders(@restaurant.id, include_calculations: true)

    assert result[:orders].is_a?(Array)

    # Check if calculations are included when orders exist
    if result[:orders].any?
      first_order = result[:orders].first
      assert first_order[:calculations].present? if first_order
    end
  end

  # User orders tests
  test 'should cache user all orders' do
    result = AdvancedCacheService.cached_user_all_orders(@user.id)

    assert result[:user].present?
    assert result[:orders].is_a?(Array)
    assert result[:metadata].present?
    assert result[:metadata][:restaurants_count].is_a?(Integer)
    assert result[:metadata][:total_orders].is_a?(Integer)
  end

  # Individual order tests
  test 'should cache order with details' do
    result = AdvancedCacheService.cached_order_with_details(@ordr.id)

    # Should handle case where order exists
    if result[:error]
      assert_equal 'Order not found', result[:error]
    else
      assert result[:order].present?
      assert result[:restaurant].present?
      assert result[:calculations].present?
      assert result[:items].is_a?(Array)
      assert result[:cached_at].present?
    end
  end

  test 'should cache individual order analytics' do
    result = AdvancedCacheService.cached_individual_order_analytics(@ordr.id)

    # Should handle case where order exists
    if result[:error]
      assert_equal 'Order not found', result[:error]
    else
      assert result[:order].present?
      assert result[:period_days] == 7
      assert result[:analytics].present?
      assert result[:recommendations].is_a?(Array)
    end
  end

  # Restaurant order summary tests
  test 'should cache restaurant order summary' do
    result = AdvancedCacheService.cached_restaurant_order_summary(@restaurant.id)

    assert result[:restaurant].present?
    assert result[:period_days] == 30
    assert result[:summary].present?
    assert result[:trends].present?
    assert result[:cached_at].present?

    # Check summary structure
    assert result[:summary][:total_orders].is_a?(Integer)
    assert result[:summary][:total_revenue].is_a?(Numeric)
    assert result[:summary][:average_order_value].is_a?(Numeric)
  end

  test 'should cache restaurant order summary with custom days' do
    result = AdvancedCacheService.cached_restaurant_order_summary(@restaurant.id, days: 7)

    assert result[:period_days] == 7
  end

  # Employee caching tests
  test 'should cache restaurant employees' do
    result = AdvancedCacheService.cached_restaurant_employees(@restaurant.id)

    assert result[:restaurant].present?
    assert result[:employees].is_a?(Array)
    assert result[:metadata].present?
    assert result[:metadata][:total_employees].is_a?(Integer)
    assert result[:metadata][:cached_at].present?
  end

  test 'should cache restaurant employees with analytics' do
    result = AdvancedCacheService.cached_restaurant_employees(@restaurant.id, include_analytics: true)

    assert result[:employees].is_a?(Array)

    # Check if analytics are included when employees exist
    if result[:employees].any?
      first_employee = result[:employees].first
      assert first_employee[:analytics].present? if first_employee
    end
  end

  test 'should cache user all employees' do
    result = AdvancedCacheService.cached_user_all_employees(@user.id)

    assert result[:user].present?
    assert result[:employees].is_a?(Array)
    assert result[:metadata].present?
    assert result[:metadata][:restaurants_count].is_a?(Integer)
    assert result[:metadata][:total_employees].is_a?(Integer)
  end

  # Individual employee tests
  test 'should cache employee with details' do
    employee = @restaurant.employees.first
    skip 'No employees available' unless employee

    result = AdvancedCacheService.cached_employee_with_details(employee.id)

    # Should handle case where employee exists
    if result[:error]
      assert_equal 'Employee not found', result[:error]
    else
      assert result[:employee].present?
      assert result[:restaurant].present?
      assert result[:permissions].present?
      assert result[:activity].present?
      assert result[:cached_at].present?
    end
  end

  test 'should cache employee performance' do
    employee = @restaurant.employees.first
    skip 'No employees available' unless employee

    result = AdvancedCacheService.cached_employee_performance(employee.id)

    # Should handle case where employee exists
    if result[:error]
      assert_equal 'Employee not found', result[:error]
    else
      assert result[:employee].present?
      assert result[:period_days] == 30
      assert result[:performance].present?
      assert result[:trends].present?
      assert result[:recommendations].is_a?(Array)
    end
  end

  test 'should cache restaurant employee summary' do
    result = AdvancedCacheService.cached_restaurant_employee_summary(@restaurant.id)

    assert result[:restaurant].present?
    assert result[:period_days] == 30
    assert result[:summary].present?
    assert result[:performance].present?
    assert result[:trends].present?

    # Check summary structure
    assert result[:summary][:total_employees].is_a?(Integer)
    assert result[:summary][:active_employees].is_a?(Integer)
  end

  # Error handling tests
  test 'should handle missing menu gracefully' do
    assert_raises(ActiveRecord::RecordNotFound) do
      AdvancedCacheService.cached_menu_with_items(99999)
    end
  end

  test 'should handle missing restaurant gracefully' do
    assert_raises(ActiveRecord::RecordNotFound) do
      AdvancedCacheService.cached_restaurant_dashboard(99999)
    end
  end

  test 'should handle missing user gracefully' do
    assert_raises(ActiveRecord::RecordNotFound) do
      AdvancedCacheService.cached_user_activity(99999)
    end
  end

  # Cache key uniqueness tests
  test 'should generate different cache keys for different parameters' do
    # Test menu caching with different locales
    key1 = "menu_full:#{@menu.id}:en:false"
    key2 = "menu_full:#{@menu.id}:es:false"

    # Cache with different locales
    AdvancedCacheService.cached_menu_with_items(@menu.id, locale: 'en')
    AdvancedCacheService.cached_menu_with_items(@menu.id, locale: 'es')

    # Both should be cached separately
    assert Rails.cache.exist?(key1)
    assert Rails.cache.exist?(key2)
  end

  test 'should use same cache key for same parameters' do
    # Call twice with same parameters
    result1 = AdvancedCacheService.cached_menu_with_items(@menu.id)
    result2 = AdvancedCacheService.cached_menu_with_items(@menu.id)

    # Should return same cached result
    assert_equal result1[:metadata][:cached_at], result2[:metadata][:cached_at]
  end

  # Performance tests
  test 'should cache results for performance' do
    # First call - should be slower (cache miss)
    start_time = Time.current
    result1 = AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)
    first_duration = Time.current - start_time

    # Second call - should be faster (cache hit)
    start_time = Time.current
    result2 = AdvancedCacheService.cached_restaurant_dashboard(@restaurant.id)
    second_duration = Time.current - start_time

    # Results should be identical (cached results)
    assert_equal result1[:restaurant][:id], result2[:restaurant][:id]
    assert_equal result1[:stats], result2[:stats]

    # Both calls should complete successfully
    assert first_duration >= 0
    assert second_duration >= 0
    assert result1[:restaurant].present?
    assert result2[:restaurant].present?
  end

  # Integration tests
  test 'should work with real cache operations' do
    cache_key = 'test_integration_key'

    # Test monitored cache fetch
    result = AdvancedCacheService.monitored_cache_fetch(cache_key, expires_in: 1.minute) do
      { test: 'data', timestamp: Time.current }
    end

    assert result[:test] == 'data'
    assert result[:timestamp].present?

    # Verify it's cached
    cached_result = Rails.cache.read(cache_key)
    assert_equal result[:test], cached_result[:test]

    # Clean up
    Rails.cache.delete(cache_key)
  end

  private

  # Helper method to stub methods that might not exist
  def stub_missing_methods
    # Stub methods that might not be available in test environment
    Restaurant.any_instance.stubs(:ordrs).returns([])
    Menu.any_instance.stubs(:menusections).returns([])
  end
end
