# frozen_string_literal: true

require 'test_helper'

class CacheKeyServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @ordr = ordrs(:one)
    @currency = Money::Currency.new('USD')
  end

  test "should generate optimized menu content key" do
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    assert key.is_a?(String)
    assert key.include?("menu_content")
    assert key.include?(@menu.id.to_s)
    assert key.include?(@ordr.id.to_s)
    # Currency is formatted as symbol, so check for $ presence
    assert key.include?("currency:$"), "Expected key to contain 'currency:$', but got: #{key}"
  end

  test "should generate modal content key" do
    key = CacheKeyService.modal_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    assert key.is_a?(String)
    assert key.include?("modals")
    assert key.include?(@menu.id.to_s)
  end

  test "should generate restaurant cache key" do
    key = CacheKeyService.restaurant_cache_key(
      restaurant: @restaurant,
      include_menus: true
    )
    
    assert key.is_a?(String)
    assert key.include?("restaurant")
    assert key.include?(@restaurant.id.to_s)
    assert key.include?("menus")
  end

  test "should optimize long cache keys" do
    # Create a very long key
    long_params = {
      ordr: @ordr,
      menu: @menu,
      currency: @currency,
      allergyns_updated_at: Time.current
    }
    
    key = CacheKeyService.menu_content_key(**long_params)
    
    # Should not exceed Redis key length limits
    assert key.length <= 250
  end

  test "should handle cache invalidation" do
    # Test that invalidation methods don't raise errors
    assert_nothing_raised do
      CacheKeyService.invalidate_menu_cache(@menu.id)
      CacheKeyService.invalidate_restaurant_cache(@restaurant.id)
    end
  end

  test "should handle batch operations" do
    data = {
      "test_key_1" => "value_1",
      "test_key_2" => "value_2"
    }
    
    assert_nothing_raised do
      CacheKeyService.write_multiple(data)
    end
    
    # Clean up
    Rails.cache.delete("test_key_1")
    Rails.cache.delete("test_key_2")
  end

  test "should generate API response keys" do
    key = CacheKeyService.api_response_key(
      controller: 'restaurants',
      action: 'index',
      params: { page: 1, per_page: 10 }
    )
    
    assert key.is_a?(String)
    assert key.include?("api:v1:restaurants:index")
  end

  test "should handle cache warming" do
    assert_nothing_raised do
      CacheKeyService.warm_menu_cache(@menu)
    end
  end

  test "should handle empty batch operations gracefully" do
    result = CacheKeyService.fetch_multiple({})
    assert_equal({}, result)
    
    assert_nothing_raised do
      CacheKeyService.write_multiple({})
    end
  end

  test "should generate consistent keys for same inputs" do
    key1 = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    key2 = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    assert_equal key1, key2
  end

  test "should generate different keys for different inputs" do
    key1 = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    # Different currency should generate different key
    eur_currency = Money::Currency.new('EUR')
    key2 = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: eur_currency
    )
    
    assert_not_equal key1, key2
  end
end
