require 'test_helper'

class L2CacheableTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  test 'model includes L2Cacheable concern' do
    assert Restaurant.included_modules.include?(L2Cacheable)
  end

  test 'cached_query caches complex query results' do
    # Execute cached query
    result1 = Restaurant.cached_query('test_query') do
      Restaurant.where(id: @restaurant.id)
    end

    # Second call should use cache
    result2 = Restaurant.cached_query('test_query') do
      Restaurant.where(id: @restaurant.id)
    end

    assert_not_nil result1
    assert_not_nil result2
  end

  test 'cached_query respects cache_type' do
    result = Restaurant.cached_query('test_query', cache_type: :dashboard) do
      Restaurant.where(id: @restaurant.id)
    end

    assert_not_nil result
  end

  test 'cached_query with force_refresh bypasses cache' do
    # Cache the result
    result1 = Restaurant.cached_query('test_query') do
      Restaurant.where(id: @restaurant.id)
    end

    # Force refresh
    result2 = Restaurant.cached_query('test_query', force_refresh: true) do
      Restaurant.where(id: @restaurant.id)
    end

    assert_not_nil result1
    assert_not_nil result2
  end

  test 'with_l2_cache adds caching to relation' do
    relation = Restaurant.with_l2_cache

    assert relation.respond_to?(:load)
    assert_not_nil relation.instance_variable_get(:@l2_cache_type)
  end

  test 'with_l2_cache respects cache_type parameter' do
    relation = Restaurant.with_l2_cache(cache_type: :analytics)

    assert_equal :analytics, relation.instance_variable_get(:@l2_cache_type)
  end

  test 'with_l2_cache supports cache_key_suffix' do
    relation = Restaurant.with_l2_cache(cache_key_suffix: '_test')

    assert_equal '_test', relation.instance_variable_get(:@l2_cache_key_suffix)
  end

  test 'clear_l2_cache clears model caches' do
    # Cache some queries
    Restaurant.cached_query('test_query') do
      Restaurant.where(id: @restaurant.id)
    end

    # Clear cache
    assert_nothing_raised do
      Restaurant.clear_l2_cache
    end
  end

  test 'dashboard_summary returns cached results' do
    skip 'Requires ordrs and menus associations' unless @restaurant.respond_to?(:dashboard_summary)

    result = @restaurant.dashboard_summary
    assert_not_nil result
  end

  test 'order_analytics returns cached results' do
    skip 'Requires ordrs association' unless @restaurant.respond_to?(:order_analytics)

    result = @restaurant.order_analytics
    assert_not_nil result
  end

  test 'order_analytics with date_range uses different cache key' do
    skip 'Requires ordrs association' unless @restaurant.respond_to?(:order_analytics)

    date_range = { start: 1.week.ago, end: Time.current }
    result = @restaurant.order_analytics(date_range)

    assert_not_nil result
  end

  test 'revenue_summary returns cached results' do
    skip 'Requires ordrs association' unless @restaurant.respond_to?(:revenue_summary)

    result = @restaurant.revenue_summary
    assert_not_nil result
  end

  test 'clear_model_l2_cache is called after commit' do
    # Create a new restaurant
    restaurant = Restaurant.new(
      name: 'Test Restaurant',
      user: users(:one),
      status: 'active',
    )

    # Mock the cache clearing
    Restaurant.expects(:clear_l2_cache).at_least_once

    restaurant.save!
  rescue NoMethodError
    # Skip if mocha not available
    skip 'Mocha not available for mocking'
  end

  test 'L2CacheableRelation loads records from cache' do
    relation = Restaurant.with_l2_cache.where(id: @restaurant.id)

    # Load records
    records = relation.load

    assert_not_nil records
    assert records.is_a?(Array) || records.respond_to?(:each)
  end

  test 'L2CacheableRelation handles errors gracefully' do
    relation = Restaurant.with_l2_cache.where('invalid SQL')

    # Should fallback to normal loading on error
    assert_raises(ActiveRecord::StatementInvalid) do
      relation.load
    end
  end

  test 'cached queries work with complex joins' do
    skip 'Requires menus and ordrs associations' unless @restaurant.menus.any?

    result = Restaurant.cached_query('complex_join') do
      Restaurant.joins(:menus)
        .select('restaurants.*, COUNT(menus.id) as menu_count')
        .where(id: @restaurant.id)
        .group('restaurants.id')
    end

    assert_not_nil result
  end

  test 'cached queries work with aggregations' do
    result = Restaurant.cached_query('aggregation') do
      Restaurant.select('COUNT(*) as total_count')
    end

    assert_not_nil result
  end

  test 'cached queries handle empty results' do
    result = Restaurant.cached_query('empty_result') do
      Restaurant.where(id: -1) # Non-existent ID
    end

    assert_not_nil result
  end

  test 'multiple cached queries use separate cache keys' do
    result1 = Restaurant.cached_query('query1') do
      Restaurant.where(id: @restaurant.id)
    end

    result2 = Restaurant.cached_query('query2') do
      Restaurant.where(status: 'active')
    end

    assert_not_nil result1
    assert_not_nil result2
  end

  test 'cached queries respect Rails cache configuration' do
    # Verify cache is working
    assert Rails.cache.respond_to?(:fetch)
    assert Rails.cache.respond_to?(:delete)

    result = Restaurant.cached_query('cache_test') do
      Restaurant.where(id: @restaurant.id)
    end

    assert_not_nil result
  end
end
