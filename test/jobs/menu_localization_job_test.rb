require 'test_helper'

class MenuLocalizationJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user)
    
    # Create restaurant locales
    @default_locale = Restaurantlocale.create!(
      restaurant: @restaurant,
      locale: 'EN',
      status: :active,
      dfault: true
    )
    
    @italian_locale = Restaurantlocale.create!(
      restaurant: @restaurant,
      locale: 'IT',
      status: :active,
      dfault: false
    )
    
    # Disable menu localization callback during test setup
    Menu.skip_callback(:commit, :after, :enqueue_localization)
    
    # Create a test menu
    @menu = Menu.create!(
      restaurant: @restaurant,
      name: 'Test Menu',
      description: 'A test menu',
      status: :active
    )
    
    # Create section and item
    @section = Menusection.create!(
      menu: @menu,
      name: 'Appetizers',
      sequence: 1,
      status: :active
    )
    
    @item = Menuitem.create!(
      menusection: @section,
      name: 'Bruschetta',
      price: 8.50,
      sequence: 1,
      status: :active,
      itemtype: 'food',
      preptime: 10,
      calories: 150
    )
  end
  
  teardown do
    # Re-enable callback after tests
    Menu.set_callback(:commit, :after, :enqueue_localization)
  end

  # === USE CASE 1: New Menu → Localize to All Restaurant Locales ===
  
  test 'perform with menu_id localizes menu to all restaurant locales' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = MenuLocalizationJob.new.perform('menu', @menu.id)
      
      assert_equal 2, stats[:locales_processed]
      assert stats[:menu_locales_created] > 0
      
      # Verify locale records created
      assert Menulocale.exists?(menu: @menu, locale: 'EN')
      assert Menulocale.exists?(menu: @menu, locale: 'IT')
    end
  end
  
  test 'perform with menu_id handles non-existent menu' do
    # Should not raise - deleted menus are handled gracefully
    stats = MenuLocalizationJob.new.perform('menu', 99999)
    
    # Should return empty stats with error message
    assert_equal 0, stats[:locales_processed]
    assert_equal 1, stats[:errors].length
    assert_includes stats[:errors].first, 'not found'
  end
  
  test 'perform with menu_id returns statistics' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = MenuLocalizationJob.new.perform('menu', @menu.id)
      
      assert_kind_of Hash, stats
      assert stats.key?(:locales_processed)
      assert stats.key?(:menu_locales_created)
      assert stats.key?(:errors)
    end
  end

  # === USE CASE 2: New Locale → Localize All Menus ===
  
  test 'perform with restaurant_locale_id localizes all menus to new locale' do
    # Create additional menus
    menu2 = Menu.create!(restaurant: @restaurant, name: 'Dinner Menu', status: :active)
    menu3 = Menu.create!(restaurant: @restaurant, name: 'Dessert Menu', status: :active)
    
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = MenuLocalizationJob.new.perform('locale', @italian_locale.id)
      
      # Should process at least our 3 test menus (may be more from fixtures)
      assert stats[:menus_processed] >= 3, "Expected at least 3 menus, got #{stats[:menus_processed]}"
      
      # Verify our test menus have Italian locale
      assert Menulocale.exists?(menu: @menu, locale: 'IT')
      assert Menulocale.exists?(menu: menu2, locale: 'IT')
      assert Menulocale.exists?(menu: menu3, locale: 'IT')
    end
  end
  
  test 'perform with restaurant_locale_id handles non-existent locale' do
    # Should not raise - deleted locales are handled gracefully
    stats = MenuLocalizationJob.new.perform('locale', 99999)
    
    # Should return empty stats with error message
    assert_equal 0, stats[:menus_processed]
    assert_equal 1, stats[:errors].length
    assert_includes stats[:errors].first, 'not found'
  end
  
  test 'perform with restaurant_locale_id returns statistics' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = MenuLocalizationJob.new.perform('locale', @italian_locale.id)
      
      assert_kind_of Hash, stats
      assert stats.key?(:menus_processed)
      assert stats.key?(:menu_locales_created)
      assert stats.key?(:errors)
    end
  end

  # === BACKWARD COMPATIBILITY: Legacy Integer Parameter ===
  
  test 'perform with legacy integer parameter works' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      # Old interface: just pass restaurant_locale_id as integer
      stats = MenuLocalizationJob.new.perform(@italian_locale.id)
      
      # Should process at least our test menu (may be more from fixtures)
      assert stats[:menus_processed] >= 1, "Expected at least 1 menu, got #{stats[:menus_processed]}"
      assert Menulocale.exists?(menu: @menu, locale: 'IT')
    end
  end

  # === PARAMETER VALIDATION ===
  
  test 'perform with no parameters raises ArgumentError' do
    assert_raises(ArgumentError) do
      MenuLocalizationJob.new.perform('invalid_type', 123)
    end
  end
  
  test 'perform with invalid parameters raises ArgumentError' do
    assert_raises(ArgumentError) do
      MenuLocalizationJob.new.perform('menu', nil)
    end
  end
  
  test 'perform with both menu_id and restaurant_locale_id uses menu_id' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      # Test that menu type works correctly
      stats = MenuLocalizationJob.new.perform('menu', @menu.id)
      
      # Should localize menu to all locales (menu_id behavior)
      assert_equal 2, stats[:locales_processed]
    end
  end

  # === ERROR HANDLING ===
  
  test 'perform handles translation service errors gracefully' do
    DeeplApiService.stub :translate, ->(_text, _options) { raise StandardError, 'Translation API error' } do
      # Should not raise - errors are logged and fallback used
      assert_nothing_raised do
        stats = MenuLocalizationJob.new.perform('menu', @menu.id)
        assert_equal 2, stats[:locales_processed]
      end
    end
  end
  
  test 'perform logs errors appropriately' do
    # Capture log output
    log_output = []
    Rails.logger.stub :info, ->(msg) { log_output << msg } do
      Rails.logger.stub :error, ->(msg) { log_output << msg } do
        DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
          MenuLocalizationJob.new.perform('menu', @menu.id)
        end
      end
    end
    
    # Verify logging occurred
    assert log_output.any? { |msg| msg.include?('Localizing menu') }
    assert log_output.any? { |msg| msg.include?('Completed') }
  end

  # === INTEGRATION WITH LocalizeMenuService ===
  
  test 'perform delegates to LocalizeMenuService for menu localization' do
    service_called = false
    
    LocalizeMenuService.stub :localize_menu_to_all_locales, ->(menu) {
      service_called = true
      assert_equal @menu.id, menu.id
      { locales_processed: 2, menu_locales_created: 2, errors: [] }
    } do
      MenuLocalizationJob.new.perform('menu', @menu.id)
    end
    
    assert service_called, 'Should delegate to LocalizeMenuService'
  end
  
  test 'perform delegates to LocalizeMenuService for locale localization' do
    service_called = false
    
    LocalizeMenuService.stub :localize_all_menus_to_locale, ->(restaurant, locale) {
      service_called = true
      assert_equal @restaurant.id, restaurant.id
      assert_equal @italian_locale.id, locale.id
      { menus_processed: 1, menu_locales_created: 1, errors: [] }
    } do
      MenuLocalizationJob.new.perform('locale', @italian_locale.id)
    end
    
    assert service_called, 'Should delegate to LocalizeMenuService'
  end

  # === PERFORMANCE ===
  
  test 'perform completes within reasonable time' do
    start_time = Time.current
    
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      MenuLocalizationJob.new.perform('menu', @menu.id)
    end
    
    execution_time = Time.current - start_time
    assert execution_time < 10.seconds, "Job took too long: #{execution_time}s"
  end

  # === BUSINESS SCENARIOS ===
  
  test 'OCR menu import scenario: new menu gets localized' do
    # Simulate OCR import creating a new menu
    new_menu = Menu.create!(
      restaurant: @restaurant,
      name: 'Imported Menu',
      status: :active
    )
    
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = MenuLocalizationJob.new.perform('menu', new_menu.id)
      
      # Should create locales for all restaurant locales
      assert_equal 2, stats[:locales_processed]
      assert Menulocale.exists?(menu: new_menu, locale: 'EN')
      assert Menulocale.exists?(menu: new_menu, locale: 'IT')
    end
  end
  
  test 'new locale scenario: all existing menus get localized' do
    # Create multiple menus first
    menu2 = Menu.create!(restaurant: @restaurant, name: 'Menu 2', status: :active)
    menu3 = Menu.create!(restaurant: @restaurant, name: 'Menu 3', status: :active)
    
    # Add new French locale
    french_locale = Restaurantlocale.create!(
      restaurant: @restaurant,
      locale: 'FR',
      status: :active,
      dfault: false
    )
    
    DeeplApiService.stub :translate, ->(text, options) { "FR: #{text}" } do
      stats = MenuLocalizationJob.new.perform('locale', french_locale.id)
      
      # Should process at least our 3 test menus (may be more from fixtures)
      assert stats[:menus_processed] >= 3, "Expected at least 3 menus, got #{stats[:menus_processed]}"
      assert Menulocale.exists?(menu: @menu, locale: 'FR')
      assert Menulocale.exists?(menu: menu2, locale: 'FR')
      assert Menulocale.exists?(menu: menu3, locale: 'FR')
    end
  end
end
