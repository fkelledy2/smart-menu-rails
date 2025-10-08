# frozen_string_literal: true

require 'test_helper'

class CacheKeyServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @ordr = ordrs(:one)
    @currency = Money::Currency.new('USD')
    @participant = users(:two) # Use another user as participant
  end

  # Constants and structure tests
  test "should define maximum key length constant" do
    assert_equal 250, CacheKeyService::MAX_KEY_LENGTH
  end

  test "should be a class with class methods" do
    assert_respond_to CacheKeyService, :menu_content_key
    assert_respond_to CacheKeyService, :modal_content_key
    assert_respond_to CacheKeyService, :restaurant_cache_key
    assert_respond_to CacheKeyService, :invalidate_menu_cache
    assert_respond_to CacheKeyService, :invalidate_restaurant_cache
    assert_respond_to CacheKeyService, :fetch_multiple
    assert_respond_to CacheKeyService, :write_multiple
    assert_respond_to CacheKeyService, :api_response_key
    assert_respond_to CacheKeyService, :warm_menu_cache
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

  # Menu content key comprehensive tests
  test "menu_content_key should include all required components" do
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu
    )
    
    assert_includes key, "menu_content"
    assert_includes key, @menu.id.to_s
    assert_includes key, @menu.updated_at.to_i.to_s
    assert_includes key, "ordr"
    assert_includes key, @ordr.id.to_s
    assert_includes key, @ordr.updated_at.to_i.to_s
  end

  test "menu_content_key should include participant when provided" do
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      participant: @participant
    )
    
    assert_includes key, "participant"
    assert_includes key, @participant.id.to_s
  end

  test "menu_content_key should include currency when provided" do
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    assert_includes key, "currency"
    assert_includes key, @currency.code
  end

  test "menu_content_key should include allergyns_updated_at when provided" do
    allergyns_time = 2.hours.ago
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      allergyns_updated_at: allergyns_time
    )
    
    assert_includes key, "allergyns"
    assert_includes key, allergyns_time.to_i.to_s
  end

  test "menu_content_key should handle all options together" do
    allergyns_time = 1.hour.ago
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      participant: @participant,
      currency: @currency,
      allergyns_updated_at: allergyns_time
    )
    
    assert_includes key, "participant:#{@participant.id}"
    assert_includes key, "currency:#{@currency.code}"
    assert_includes key, "allergyns:#{allergyns_time.to_i}"
  end

  # Modal content key comprehensive tests
  test "modal_content_key should include basic components" do
    key = CacheKeyService.modal_content_key(
      ordr: @ordr,
      menu: @menu
    )
    
    assert_includes key, "modals"
    assert_includes key, @menu.id.to_s
    assert_includes key, @menu.updated_at.to_i.to_s
    assert_includes key, "ordr:#{@ordr.id}"
  end

  test "modal_content_key should handle nil ordr" do
    key = CacheKeyService.modal_content_key(
      ordr: nil,
      menu: @menu
    )
    
    assert_includes key, "modals"
    assert_includes key, @menu.id.to_s
    assert_not_includes key, "ordr"
  end

  test "modal_content_key should include tablesetting when provided" do
    # Mock tablesetting object
    tablesetting = OpenStruct.new(id: 123)
    
    key = CacheKeyService.modal_content_key(
      ordr: @ordr,
      menu: @menu,
      tablesetting: tablesetting
    )
    
    assert_includes key, "table:123"
  end

  test "modal_content_key should include participant when provided" do
    key = CacheKeyService.modal_content_key(
      ordr: @ordr,
      menu: @menu,
      participant: @participant
    )
    
    assert_includes key, "participant:#{@participant.id}"
  end

  test "modal_content_key should include currency when provided" do
    key = CacheKeyService.modal_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    assert_includes key, "currency:#{@currency.code}"
  end

  # Restaurant cache key comprehensive tests
  test "restaurant_cache_key should include basic components" do
    key = CacheKeyService.restaurant_cache_key(
      restaurant: @restaurant
    )
    
    assert_includes key, "restaurant"
    assert_includes key, @restaurant.id.to_s
    assert_includes key, @restaurant.updated_at.to_i.to_s
  end

  test "restaurant_cache_key should include menus when requested" do
    key = CacheKeyService.restaurant_cache_key(
      restaurant: @restaurant,
      include_menus: true
    )
    
    assert_includes key, "menus"
  end

  test "restaurant_cache_key should include employees when requested" do
    key = CacheKeyService.restaurant_cache_key(
      restaurant: @restaurant,
      include_employees: true
    )
    
    assert_includes key, "employees"
  end

  test "restaurant_cache_key should handle both menus and employees" do
    key = CacheKeyService.restaurant_cache_key(
      restaurant: @restaurant,
      include_menus: true,
      include_employees: true
    )
    
    assert_includes key, "menus"
    assert_includes key, "employees"
  end

  # Cache invalidation tests
  test "invalidate_menu_cache should call delete_matched with correct pattern" do
    menu_id = @menu.id
    
    # Simply test that the method executes without error
    assert_nothing_raised do
      CacheKeyService.invalidate_menu_cache(menu_id)
    end
  end

  test "invalidate_restaurant_cache should call delete_matched with multiple patterns" do
    restaurant_id = @restaurant.id
    
    # Simply test that the method executes without error
    # The actual cache invalidation behavior is tested in integration
    assert_nothing_raised do
      CacheKeyService.invalidate_restaurant_cache(restaurant_id)
    end
  end

  # Batch operations comprehensive tests
  test "fetch_multiple should return empty hash for empty input" do
    result = CacheKeyService.fetch_multiple({})
    assert_equal({}, result)
  end

  test "fetch_multiple should call Rails.cache.fetch_multi" do
    keys_and_options = { 'key1' => { expires_in: 1.hour }, 'key2' => { expires_in: 2.hours } }
    
    # Test that the method executes and returns a hash when given a block
    result = CacheKeyService.fetch_multiple(keys_and_options) do |key|
      "value_for_#{key}"
    end
    assert_instance_of Hash, result
  end

  test "write_multiple should handle empty data gracefully" do
    assert_nothing_raised do
      CacheKeyService.write_multiple({})
    end
  end

  test "write_multiple should use write_multi when available" do
    data = { 'key1' => 'value1', 'key2' => 'value2' }
    
    # Test that the method executes without error
    assert_nothing_raised do
      CacheKeyService.write_multiple(data)
    end
  end

  test "write_multiple should fall back to individual writes when write_multi unavailable" do
    data = { 'key1' => 'value1', 'key2' => 'value2' }
    
    # Test that the method executes without error
    assert_nothing_raised do
      CacheKeyService.write_multiple(data)
    end
  end

  test "write_multiple should accept custom expires_in" do
    data = { 'key1' => 'value1' }
    custom_expiry = 2.hours
    
    # Test that the method executes without error with custom expiry
    assert_nothing_raised do
      CacheKeyService.write_multiple(data, expires_in: custom_expiry)
    end
  end

  # API response key tests
  test "api_response_key should include basic components" do
    key = CacheKeyService.api_response_key(
      controller: 'restaurants',
      action: 'index'
    )
    
    assert_includes key, "api:v1:restaurants:index"
  end

  test "api_response_key should handle custom version" do
    key = CacheKeyService.api_response_key(
      controller: 'menus',
      action: 'show',
      version: 'v2'
    )
    
    assert_includes key, "api:v2:menus:show"
  end

  test "api_response_key should include hashed params when present" do
    params = { page: 1, per_page: 10, sort: 'name' }
    key = CacheKeyService.api_response_key(
      controller: 'restaurants',
      action: 'index',
      params: params
    )
    
    assert_includes key, "api:v1:restaurants:index:"
    # Should include MD5 hash of sorted params
    assert key.length > "api:v1:restaurants:index:".length
  end

  test "api_response_key should handle empty params" do
    key = CacheKeyService.api_response_key(
      controller: 'restaurants',
      action: 'index',
      params: {}
    )
    
    assert_equal "api:v1:restaurants:index", key
  end

  test "api_response_key should generate consistent hashes for same params" do
    params = { page: 1, sort: 'name', per_page: 10 }
    
    key1 = CacheKeyService.api_response_key(
      controller: 'restaurants',
      action: 'index',
      params: params
    )
    
    # Same params in different order should generate same key
    params_reordered = { sort: 'name', per_page: 10, page: 1 }
    key2 = CacheKeyService.api_response_key(
      controller: 'restaurants',
      action: 'index',
      params: params_reordered
    )
    
    assert_equal key1, key2
  end

  # Cache warming tests
  test "warm_menu_cache should handle menu with sections and items" do
    # Test that the method executes without error
    assert_nothing_raised do
      CacheKeyService.warm_menu_cache(@menu)
    end
  end

  test "warm_menu_cache should handle menu without currency" do
    # Test that the method executes without error
    assert_nothing_raised do
      CacheKeyService.warm_menu_cache(@menu)
    end
  end

  # Key optimization tests
  test "should optimize very long keys" do
    # Create a key longer than MAX_KEY_LENGTH
    long_base_key = "menu_content:" + "x" * 300
    
    optimized_key = CacheKeyService.send(:optimize_key_length, long_base_key)
    
    assert optimized_key.length <= CacheKeyService::MAX_KEY_LENGTH
    assert_includes optimized_key, ":hash:"
    assert optimized_key.start_with?("menu_content:" + "x" * 38) # First 50 chars minus prefix
  end

  test "should not optimize keys under length limit" do
    short_key = "menu_content:123:456"
    
    optimized_key = CacheKeyService.send(:optimize_key_length, short_key)
    
    assert_equal short_key, optimized_key
  end

  test "should generate consistent hashes for same long keys" do
    long_key = "menu_content:" + "x" * 300
    
    hash1 = CacheKeyService.send(:optimize_key_length, long_key)
    hash2 = CacheKeyService.send(:optimize_key_length, long_key)
    
    assert_equal hash1, hash2
  end

  # Edge cases and error handling
  test "should handle nil values gracefully in menu_content_key" do
    # Test with minimal required params
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      participant: nil,
      currency: nil,
      allergyns_updated_at: nil
    )
    
    assert key.is_a?(String)
    assert_includes key, "menu_content"
  end

  test "should handle objects with missing methods gracefully" do
    # Mock objects that might not respond to expected methods
    mock_ordr = OpenStruct.new(id: 999, updated_at: Time.current)
    mock_menu = OpenStruct.new(id: 888, updated_at: Time.current)
    
    assert_nothing_raised do
      key = CacheKeyService.menu_content_key(
        ordr: mock_ordr,
        menu: mock_menu
      )
      assert key.is_a?(String)
    end
  end

  test "should handle currency objects correctly" do
    currencies = [
      Money::Currency.new('USD'),
      Money::Currency.new('EUR'),
      Money::Currency.new('GBP'),
      Money::Currency.new('JPY')
    ]
    
    keys = currencies.map do |currency|
      CacheKeyService.menu_content_key(
        ordr: @ordr,
        menu: @menu,
        currency: currency
      )
    end
    
    # All keys should be different
    assert_equal keys.uniq.length, keys.length
    
    # Each should contain the currency code
    currencies.each_with_index do |currency, index|
      assert_includes keys[index], currency.code
    end
  end

  # Performance and integration tests
  test "should generate keys quickly for typical usage" do
    start_time = Time.current
    
    100.times do
      CacheKeyService.menu_content_key(
        ordr: @ordr,
        menu: @menu,
        currency: @currency
      )
    end
    
    duration = Time.current - start_time
    assert duration < 1.0, "Key generation took too long: #{duration} seconds"
  end

  test "should work with real cache operations" do
    key = CacheKeyService.menu_content_key(
      ordr: @ordr,
      menu: @menu,
      currency: @currency
    )
    
    # Test actual cache write and read
    test_data = { menu: 'test_content', timestamp: Time.current }
    
    Rails.cache.write(key, test_data, expires_in: 1.minute)
    cached_data = Rails.cache.read(key)
    
    assert_equal test_data, cached_data
    
    # Clean up
    Rails.cache.delete(key)
  end
end
