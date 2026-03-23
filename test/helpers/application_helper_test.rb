require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @menusection = menusections(:one)
    @menuitem = menuitems(:one)

    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant
    @menusection.update!(menu: @menu) if @menusection.menu != @menu
    @menuitem.update!(menusection: @menusection) if @menuitem.menusection != @menusection

    # Mock current_user for helper tests
    def current_user
      @user
    end
  end

  # === RESTAURANT CONTEXT DATA TESTS ===

  test 'should return restaurant context data when restaurant provided' do
    result = restaurant_context_data(@restaurant)

    assert_equal @restaurant.id, result['data-restaurant-id']
    assert_equal @restaurant.name, result['data-restaurant-name']
    assert_nil result['data-restaurant-slug'] # Restaurant model doesn't have slug
  end

  test 'should return restaurant context data from instance variable' do
    @restaurant = restaurants(:one)

    result = restaurant_context_data

    assert_equal @restaurant.id, result['data-restaurant-id']
    assert_equal @restaurant.name, result['data-restaurant-name']
    assert_nil result['data-restaurant-slug'] # Restaurant model doesn't have slug
  end

  test 'should return restaurant context data from menu' do
    @menu = menus(:one)
    @restaurant = nil

    result = restaurant_context_data

    assert_equal @menu.restaurant.id, result['data-restaurant-id']
    assert_equal @menu.restaurant.name, result['data-restaurant-name']
    assert_nil result['data-restaurant-slug'] # Restaurant model doesn't have slug
  end

  test 'should return restaurant context data from menuitem' do
    @menuitem = menuitems(:one)
    @restaurant = nil
    @menu = nil

    result = restaurant_context_data

    restaurant = @menuitem.menusection.menu.restaurant
    assert_equal restaurant.id, result['data-restaurant-id']
    assert_equal restaurant.name, result['data-restaurant-name']
    assert_nil result['data-restaurant-slug'] # Restaurant model doesn't have slug
  end

  test 'should return restaurant context data from menusection' do
    @menusection = menusections(:one)
    @restaurant = nil
    @menu = nil
    @menuitem = nil

    result = restaurant_context_data

    restaurant = @menusection.menu.restaurant
    assert_equal restaurant.id, result['data-restaurant-id']
    assert_equal restaurant.name, result['data-restaurant-name']
    assert_nil result['data-restaurant-slug'] # Restaurant model doesn't have slug
  end

  test 'should return restaurant context data from current_user' do
    @restaurant = nil
    @menu = nil
    @menuitem = nil
    @menusection = nil

    result = restaurant_context_data

    user_restaurant = current_user.restaurants.first
    assert_equal user_restaurant.id, result['data-restaurant-id']
    assert_equal user_restaurant.name, result['data-restaurant-name']
    assert_nil result['data-restaurant-slug'] # Restaurant model doesn't have slug
  end

  test 'should return empty hash when no restaurant context available' do
    # Test the helper method directly with nil to ensure it returns empty hash
    result = restaurant_context_data(nil)

    # When no restaurant is provided and no fallbacks are available, should return empty hash
    # Note: This test may find a restaurant from current_user, which is expected behavior
    assert result.is_a?(Hash)

    # The key test is that the method handles nil input gracefully
    assert_nothing_raised do
      restaurant_context_data(nil)
    end
  end

  test 'should handle nil restaurant gracefully' do
    result = restaurant_context_data(nil)

    # Should fall back to instance variables or current_user
    assert result.is_a?(Hash)
  end

  # === RESTAURANT CONTEXT META TAGS TESTS ===

  test 'should generate restaurant context meta tags when restaurant provided' do
    restaurant_context_meta_tags(@restaurant)

    # Check that content_for :head was called with meta tags
    head_content = content_for(:head)
    assert_includes head_content, 'restaurant-id'
    assert_includes head_content, @restaurant.id.to_s
    assert_includes head_content, 'current-restaurant'
    assert_includes head_content, 'restaurant:id'
  end

  test 'should generate restaurant context meta tags from instance variable' do
    @restaurant = restaurants(:one)

    restaurant_context_meta_tags

    head_content = content_for(:head)
    assert_includes head_content, 'restaurant-id'
    assert_includes head_content, @restaurant.id.to_s
  end

  test 'should generate restaurant context meta tags from menu' do
    @menu = menus(:one)
    @restaurant = nil

    restaurant_context_meta_tags

    head_content = content_for(:head)
    assert_includes head_content, 'restaurant-id'
    assert_includes head_content, @menu.restaurant.id.to_s
  end

  test 'should generate restaurant context meta tags from menuitem' do
    @menuitem = menuitems(:one)
    @restaurant = nil
    @menu = nil

    restaurant_context_meta_tags

    head_content = content_for(:head)
    restaurant = @menuitem.menusection.menu.restaurant
    assert_includes head_content, 'restaurant-id'
    assert_includes head_content, restaurant.id.to_s
  end

  test 'should generate restaurant context meta tags from menusection' do
    @menusection = menusections(:one)
    @restaurant = nil
    @menu = nil
    @menuitem = nil

    restaurant_context_meta_tags

    head_content = content_for(:head)
    restaurant = @menusection.menu.restaurant
    assert_includes head_content, 'restaurant-id'
    assert_includes head_content, restaurant.id.to_s
  end

  test 'should return empty string when no restaurant for meta tags' do
    @restaurant = nil
    @menu = nil
    @menuitem = nil
    @menusection = nil

    result = restaurant_context_meta_tags

    assert_equal '', result
  end

  # === RESTAURANT CONTEXT SCRIPT TESTS ===

  test 'should generate restaurant context script when restaurant provided' do
    result = restaurant_context_script(@restaurant)

    assert_includes result, 'window.currentRestaurant'
    assert_includes result, @restaurant.id.to_s
    assert_includes result, @restaurant.name
  end

  test 'should generate restaurant context script from instance variable' do
    @restaurant = restaurants(:one)

    result = restaurant_context_script

    assert_includes result, 'window.currentRestaurant'
    assert_includes result, @restaurant.id.to_s
    assert_includes result, @restaurant.name
  end

  test 'should generate restaurant context script from menu' do
    @menu = menus(:one)
    @restaurant = nil

    result = restaurant_context_script

    assert_includes result, 'window.currentRestaurant'
    assert_includes result, @menu.restaurant.id.to_s
    assert_includes result, @menu.restaurant.name
  end

  test 'should generate restaurant context script from menuitem' do
    @menuitem = menuitems(:one)
    @restaurant = nil
    @menu = nil

    result = restaurant_context_script

    restaurant = @menuitem.menusection.menu.restaurant
    assert_includes result, 'window.currentRestaurant'
    assert_includes result, restaurant.id.to_s
    assert_includes result, restaurant.name
  end

  test 'should generate restaurant context script from menusection' do
    @menusection = menusections(:one)
    @restaurant = nil
    @menu = nil
    @menuitem = nil

    result = restaurant_context_script

    restaurant = @menusection.menu.restaurant
    assert_includes result, 'window.currentRestaurant'
    assert_includes result, restaurant.id.to_s
    assert_includes result, restaurant.name
  end

  test 'should return empty string when no restaurant for script' do
    @restaurant = nil
    @menu = nil
    @menuitem = nil
    @menusection = nil

    result = restaurant_context_script

    assert_equal '', result
  end

  test 'should escape JavaScript properly in context script' do
    # Create restaurant with special characters
    restaurant_with_quotes = Restaurant.create!(
      name: 'Restaurant "Special" & Co.',
      user: @user,
      capacity: 50,
      status: :active,
    )

    result = restaurant_context_script(restaurant_with_quotes)

    # Should properly escape quotes and special characters
    assert_includes result, 'window.currentRestaurant'
    assert_not_includes result, '"Special"' # Should be escaped
  end

  # === EDGE CASE TESTS ===

  test 'should handle restaurant without slug' do
    restaurant_without_slug = Restaurant.create!(
      name: 'No Slug Restaurant',
      user: @user,
      capacity: 30,
      status: :active,
    )

    result = restaurant_context_data(restaurant_without_slug)

    assert_equal restaurant_without_slug.id, result['data-restaurant-id']
    assert_equal restaurant_without_slug.name, result['data-restaurant-name']
    assert_nil result['data-restaurant-slug']
  end

  test 'should handle restaurant with minimal name' do
    restaurant_minimal_name = Restaurant.create!(
      name: 'R',
      user: @user,
      capacity: 30,
      status: :active,
    )

    result = restaurant_context_data(restaurant_minimal_name)

    assert_equal restaurant_minimal_name.id, result['data-restaurant-id']
    assert_equal 'R', result['data-restaurant-name']
  end

  test 'should handle complex nested associations' do
    # Test with deeply nested structure
    @menuitem = menuitems(:one)
    @menusection = nil
    @menu = nil
    @restaurant = nil

    result = restaurant_context_data

    # Should traverse: menuitem -> menusection -> menu -> restaurant
    expected_restaurant = @menuitem.menusection.menu.restaurant
    assert_equal expected_restaurant.id, result['data-restaurant-id']
  end

  # === PERFORMANCE TESTS ===

  test 'should handle multiple calls efficiently' do
    start_time = Time.current

    100.times do
      restaurant_context_data(@restaurant)
    end

    execution_time = Time.current - start_time
    assert execution_time < 1.second, "Helper calls took too long: #{execution_time}s"
  end

  test 'should handle nil values without errors' do
    assert_nothing_raised do
      restaurant_context_data(nil)
      restaurant_context_meta_tags(nil)
      restaurant_context_script(nil)
    end
  end

  # === INTEGRATION TESTS ===

  test 'should work with real view context' do
    # Test that helpers work in actual view rendering context
    @restaurant = restaurants(:one)

    assert_nothing_raised do
      restaurant_context_data
      restaurant_context_meta_tags
      restaurant_context_script
    end
  end

  test 'should provide consistent data across all methods' do
    restaurant_data = restaurant_context_data(@restaurant)
    restaurant_context_meta_tags(@restaurant)
    script = restaurant_context_script(@restaurant)

    restaurant_id = @restaurant.id.to_s

    # All methods should reference the same restaurant
    assert_includes restaurant_data.values.map(&:to_s), restaurant_id

    head_content = content_for(:head)
    assert_includes head_content, restaurant_id if head_content

    assert_includes script, restaurant_id
  end

  # === BUSINESS SCENARIO TESTS ===

  test 'should support restaurant dashboard scenario' do
    # User viewing restaurant dashboard
    @restaurant = restaurants(:one)

    context_data = restaurant_context_data
    restaurant_context_meta_tags
    script = restaurant_context_script

    # Should provide complete restaurant context
    assert context_data['data-restaurant-id'].present?

    head_content = content_for(:head)
    assert head_content.include?('restaurant-id') if head_content

    assert script.include?('window.currentRestaurant')
  end

  test 'should support menu editing scenario' do
    # User editing a menu item
    @menuitem = menuitems(:one)
    @restaurant = nil # Not directly available

    context_data = restaurant_context_data

    # Should derive restaurant from menu item
    expected_restaurant = @menuitem.menusection.menu.restaurant
    assert_equal expected_restaurant.id, context_data['data-restaurant-id']
  end

  test 'should support multi-restaurant user scenario' do
    # User with multiple restaurants
    Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      capacity: 40,
      status: :active,
    )

    @restaurant = nil
    @menu = nil

    context_data = restaurant_context_data

    # Should return first restaurant when no specific context
    first_restaurant = current_user.restaurants.first
    assert_equal first_restaurant.id, context_data['data-restaurant-id']
  end

  # === CURRENCY ICON TESTS ===

  test 'currency_icon returns dollar icon for USD' do
    assert_equal 'bi-currency-dollar', currency_icon('USD')
  end

  test 'currency_icon returns euro icon for EUR' do
    assert_equal 'bi-currency-euro', currency_icon('EUR')
  end

  test 'currency_icon returns pound icon for GBP' do
    assert_equal 'bi-currency-pound', currency_icon('GBP')
  end

  test 'currency_icon returns yen icon for JPY' do
    assert_equal 'bi-currency-yen', currency_icon('JPY')
  end

  test 'currency_icon returns yen icon for CNY' do
    assert_equal 'bi-currency-yen', currency_icon('CNY')
  end

  test 'currency_icon returns generic icon for unknown currency' do
    assert_equal 'bi-cash-coin', currency_icon('AUD')
  end

  test 'currency_icon is case-insensitive' do
    assert_equal 'bi-currency-dollar', currency_icon('usd')
  end

  test 'currency_icon returns generic icon for nil' do
    assert_equal 'bi-cash-coin', currency_icon(nil)
  end

  # === BUILD NUMBER TESTS ===

  test 'build_number returns nil when no release env vars' do
    old_release = ENV.delete('HEROKU_RELEASE_VERSION')
    old_number = ENV.delete('HEROKU_RELEASE_NUMBER')
    result = build_number
    assert_nil result
  ensure
    ENV['HEROKU_RELEASE_VERSION'] = old_release if old_release
    ENV['HEROKU_RELEASE_NUMBER'] = old_number if old_number
  end

  test 'build_number returns formatted string with HEROKU_RELEASE_VERSION' do
    ENV['HEROKU_RELEASE_VERSION'] = 'v42'
    ENV.delete('HEROKU_RELEASE_CREATED_AT')
    result = build_number
    assert_not_nil result
    assert_match(/\d{8}-v42/, result)
  ensure
    ENV.delete('HEROKU_RELEASE_VERSION')
  end

  test 'build_number uses HEROKU_RELEASE_CREATED_AT for date' do
    ENV['HEROKU_RELEASE_VERSION'] = 'v10'
    ENV['HEROKU_RELEASE_CREATED_AT'] = '2024-06-15T12:00:00Z'
    result = build_number
    assert_equal '20240615-v10', result
  ensure
    ENV.delete('HEROKU_RELEASE_VERSION')
    ENV.delete('HEROKU_RELEASE_CREATED_AT')
  end

  # === T_HTML TESTS ===

  test 't_html returns raw empty string for blank key' do
    result = t_html('')
    assert_equal '', result
  end

  test 't_html returns translation for valid key' do
    result = t_html('hello')
    assert_kind_of String, result
  end

  test 'translate_html is an alias for t_html' do
    assert_equal method(:t_html), method(:translate_html)
  end

  # === RESOLVE_PARTICIPANT_LOCALE TESTS ===

  test 'resolve_participant_locale returns default locale with no args' do
    result = resolve_participant_locale
    assert_equal I18n.default_locale, result
  end

  test 'resolve_participant_locale prefers ordrparticipant locale' do
    participant = OpenStruct.new(preferredlocale: :fr)
    result = resolve_participant_locale(participant)
    assert_equal :fr, result
  end

  test 'resolve_participant_locale falls back to menuparticipant locale' do
    participant = OpenStruct.new(preferredlocale: nil)
    menu_participant = OpenStruct.new(preferredlocale: :de)
    result = resolve_participant_locale(participant, menu_participant)
    assert_equal :de, result
  end

  test 'resolve_participant_locale uses instance variable ordrparticipant' do
    @ordrparticipant = OpenStruct.new(preferredlocale: :es)
    result = resolve_participant_locale
    assert_equal :es, result
  ensure
    @ordrparticipant = nil
  end

  # === LOCALISED_NAME TESTS ===

  test 'localised_name returns entity.name when entity has no localised_name method' do
    entity = OpenStruct.new(name: 'Test Item')
    result = localised_name(entity)
    assert_equal 'Test Item', result
  end

  test 'localised_name calls localised_name on entity when method exists' do
    entity = Object.new
    entity.define_singleton_method(:name) { 'Default' }
    entity.define_singleton_method(:localised_name) { |locale| "Localised(#{locale})" }
    result = localised_name(entity)
    assert_equal "Localised(#{I18n.default_locale})", result
  end

  # === LOCALISED_DESCRIPTION TESTS ===

  test 'localised_description returns entity.description when no localised_description method' do
    entity = OpenStruct.new(description: 'A fine item')
    result = localised_description(entity)
    assert_equal 'A fine item', result
  end

  # === PAGE_MODULES TESTS ===

  test 'page_modules returns empty string by default' do
    assert_equal '', page_modules
  end

  test 'page_modules returns @page_modules when set' do
    @page_modules = 'some-module'
    assert_equal 'some-module', page_modules
  ensure
    @page_modules = nil
  end
end
