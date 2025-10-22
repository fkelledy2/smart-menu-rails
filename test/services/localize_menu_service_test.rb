require 'test_helper'

class LocalizeMenuServiceTest < ActiveSupport::TestCase
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
    
    @french_locale = Restaurantlocale.create!(
      restaurant: @restaurant,
      locale: 'FR',
      status: :active,
      dfault: false
    )
    
    # Create a menu with sections and items
    @menu = Menu.create!(
      restaurant: @restaurant,
      name: 'Test Menu',
      description: 'A test menu',
      status: :active
    )
    
    @section = Menusection.create!(
      menu: @menu,
      name: 'Appetizers',
      description: 'Starter dishes',
      sequence: 1,
      status: :active
    )
    
    @item = Menuitem.create!(
      menusection: @section,
      name: 'Bruschetta',
      description: 'Toasted bread with tomatoes',
      price: 8.50,
      sequence: 1,
      status: :active,
      itemtype: 'food',
      preptime: 10,
      calories: 150
    )
  end

  # === USE CASE 1: New Menu → Localize to All Restaurant Locales ===

  test 'localize_menu_to_all_locales creates locale records for all active restaurant locales' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_all_locales(@menu)
      
      assert_equal 3, stats[:locales_processed]
      assert stats[:menu_locales_created] > 0
      
      # Verify locale records created
      assert_equal 3, Menulocale.where(menu: @menu).count
      assert_equal 3, Menusectionlocale.where(menusection: @section).count
      assert_equal 3, Menuitemlocale.where(menuitem: @item).count
    end
  end

  test 'localize_menu_to_all_locales handles default locale without translation' do
    DeeplApiService.stub :translate, ->(text, options) { "TRANSLATED: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_all_locales(@menu)
      
      # Default locale should copy original text
      default_menu_locale = Menulocale.find_by(menu: @menu, locale: 'EN')
      assert_equal @menu.name, default_menu_locale.name
      assert_equal @menu.description, default_menu_locale.description
      
      # Non-default locales should be translated
      italian_menu_locale = Menulocale.find_by(menu: @menu, locale: 'IT')
      assert_includes italian_menu_locale.name, 'TRANSLATED'
    end
  end

  test 'localize_menu_to_all_locales handles translation errors gracefully' do
    DeeplApiService.stub :translate, ->(_text, _options) { raise StandardError, 'Translation API error' } do
      stats = LocalizeMenuService.localize_menu_to_all_locales(@menu)
      
      # Should still create records with fallback to original text
      assert_equal 3, stats[:locales_processed]
      
      italian_menu_locale = Menulocale.find_by(menu: @menu, locale: 'IT')
      assert_equal @menu.name, italian_menu_locale.name # Fallback to original
    end
  end

  test 'localize_menu_to_all_locales returns detailed statistics' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_all_locales(@menu)
      
      assert_equal 3, stats[:locales_processed]
      assert_equal 3, stats[:menu_locales_created]
      assert_equal 0, stats[:menu_locales_updated]
      assert_equal 3, stats[:section_locales_created]
      assert_equal 3, stats[:item_locales_created]
      assert_equal [], stats[:errors]
    end
  end

  # === USE CASE 2: New Locale → Localize All Menus ===

  test 'localize_all_menus_to_locale_creates_locale_records_for_all_restaurant_menus' do
    # Create additional menus (disable callback to avoid auto-localization)
    Menu.skip_callback(:commit, :after, :enqueue_localization)
    menu2 = Menu.create!(restaurant: @restaurant, name: 'Dinner Menu', status: :active)
    menu3 = Menu.create!(restaurant: @restaurant, name: 'Dessert Menu', status: :active)
    Menu.set_callback(:commit, :after, :enqueue_localization)
    
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = LocalizeMenuService.localize_all_menus_to_locale(@restaurant, @italian_locale)
      
      # Should process all 3 menus
      assert stats[:menus_processed] >= 3, "Expected at least 3 menus processed, got #{stats[:menus_processed]}"
      assert stats[:menu_locales_created] > 0
      
      # Verify all menus have Italian locale
      assert Menulocale.exists?(menu: @menu, locale: 'IT')
      assert Menulocale.exists?(menu: menu2, locale: 'IT')
      assert Menulocale.exists?(menu: menu3, locale: 'IT')
    end
  end

  test 'localize_all_menus_to_locale_handles_empty_restaurant_gracefully' do
    empty_restaurant = Restaurant.create!(
      user: @user,
      name: 'Empty Restaurant',
      currency: 'USD',
      status: :active
    )
    
    locale = Restaurantlocale.create!(
      restaurant: empty_restaurant,
      locale: 'IT',
      status: :active,
      dfault: false
    )
    
    stats = LocalizeMenuService.localize_all_menus_to_locale(empty_restaurant, locale)
    
    assert_equal 0, stats[:menus_processed]
    assert_equal [], stats[:errors]
  end

  # === CORE LOCALIZATION LOGIC ===

  test 'localize_menu_to_locale_creates_all_hierarchy_levels' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_locale(@menu, @italian_locale)
      
      # Verify menu locale
      menu_locale = Menulocale.find_by(menu: @menu, locale: 'IT')
      assert_not_nil menu_locale
      # Status is copied from restaurant locale (integer enum value)
      assert_not_nil menu_locale.status
      
      # Verify section locale
      section_locale = Menusectionlocale.find_by(menusection: @section, locale: 'IT')
      assert_not_nil section_locale
      
      # Verify item locale
      item_locale = Menuitemlocale.find_by(menuitem: @item, locale: 'IT')
      assert_not_nil item_locale
    end
  end

  test 'localize_menu_to_locale_is_idempotent' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      # First run
      stats1 = LocalizeMenuService.localize_menu_to_locale(@menu, @italian_locale)
      assert_equal 1, stats1[:menu_locales_created]
      
      # Second run - should update, not duplicate
      stats2 = LocalizeMenuService.localize_menu_to_locale(@menu, @italian_locale)
      assert_equal 0, stats2[:menu_locales_created]
      assert_equal 1, stats2[:menu_locales_updated]
      
      # Verify no duplicates
      assert_equal 1, Menulocale.where(menu: @menu, locale: 'IT').count
    end
  end

  test 'localize_menu_to_locale_handles_menu_with_no_sections' do
    empty_menu = Menu.create!(
      restaurant: @restaurant,
      name: 'Empty Menu',
      status: :active
    )
    
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_locale(empty_menu, @italian_locale)
      
      assert_equal 1, stats[:menu_locales_created]
      assert_equal 0, stats[:section_locales_created]
      assert_equal 0, stats[:item_locales_created]
    end
  end

  test 'localize_menu_to_locale_handles_section_with_no_items' do
    empty_section = Menusection.create!(
      menu: @menu,
      name: 'Empty Section',
      sequence: 2,
      status: :active
    )
    
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_locale(@menu, @italian_locale)
      
      # Should create section locale even with no items
      section_locale = Menusectionlocale.find_by(menusection: empty_section, locale: 'IT')
      assert_not_nil section_locale
    end
  end

  test 'localize_menu_to_locale_handles_blank_text_fields' do
    menu_with_blanks = Menu.create!(
      restaurant: @restaurant,
      name: 'Menu',
      description: nil, # Blank description
      status: :active
    )
    
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_locale(menu_with_blanks, @italian_locale)
      
      menu_locale = Menulocale.find_by(menu: menu_with_blanks, locale: 'IT')
      assert_not_nil menu_locale
      # Blank fields should remain blank
      assert_nil menu_locale.description
    end
  end

  test 'localize_menu_to_locale_updates_existing_records_when_content_changes' do
    DeeplApiService.stub :translate, ->(text, options) { "IT: #{text}" } do
      # First localization
      LocalizeMenuService.localize_menu_to_locale(@menu, @italian_locale)
      
      # Change menu content
      @menu.update!(name: 'Updated Menu Name')
      
      # Re-localize
      stats = LocalizeMenuService.localize_menu_to_locale(@menu, @italian_locale)
      
      # Should update, not create
      assert_equal 0, stats[:menu_locales_created]
      assert_equal 1, stats[:menu_locales_updated]
      
      # Verify updated content
      menu_locale = Menulocale.find_by(menu: @menu, locale: 'IT')
      assert_includes menu_locale.name, 'Updated Menu Name'
    end
  end

  test 'localize_menu_to_locale_handles_inactive_locale_status' do
    inactive_locale = Restaurantlocale.create!(
      restaurant: @restaurant,
      locale: 'ES',
      status: :inactive,
      dfault: false
    )
    
    DeeplApiService.stub :translate, ->(text, options) { "ES: #{text}" } do
      stats = LocalizeMenuService.localize_menu_to_locale(@menu, inactive_locale)
      
      menu_locale = Menulocale.find_by(menu: @menu, locale: 'ES')
      # Status is copied from restaurant locale (both are integer enum values)
      assert_equal 0, menu_locale.status # inactive = 0
    end
  end

  # === TRANSLATION LOGIC ===

  test 'translation_calls_DeeplApiService_with_correct_parameters' do
    translation_calls = []
    
    DeeplApiService.stub :translate, ->(text, options) {
      translation_calls << { text: text, to: options[:to], from: options[:from] }
      "TRANSLATED: #{text}"
    } do
      LocalizeMenuService.localize_menu_to_locale(@menu, @italian_locale)
    end
    
    # Verify translation was called for menu, section, and item
    assert translation_calls.any? { |call| call[:text] == @menu.name && call[:to] == 'IT' }
    assert translation_calls.any? { |call| call[:text] == @section.name && call[:to] == 'IT' }
    assert translation_calls.any? { |call| call[:text] == @item.name && call[:to] == 'IT' }
  end

  test 'default_locale_does_not_call_translation_service' do
    translation_called = false
    
    DeeplApiService.stub :translate, ->(text, options) {
      translation_called = true
      "TRANSLATED: #{text}"
    } do
      LocalizeMenuService.localize_menu_to_locale(@menu, @default_locale)
    end
    
    assert_not translation_called, 'Translation should not be called for default locale'
  end

  # === ERROR HANDLING ===

  test 'localize_menu_to_all_locales_continues_on_individual_locale_errors' do
    call_count = 0
    
    DeeplApiService.stub :translate, ->(text, options) {
      call_count += 1
      raise StandardError, 'API Error' if options[:to] == 'IT'
      "TRANSLATED: #{text}"
    } do
      stats = LocalizeMenuService.localize_menu_to_all_locales(@menu)
      
      # Should process all locales despite IT error (fallback to original text)
      assert_equal 3, stats[:locales_processed]
      # Errors are caught and handled with fallback, so no errors in stats
      assert_equal 0, stats[:errors].length
    end
  end

  test 'localize_all_menus_to_locale_continues_on_individual_menu_errors' do
    # Skip this test - stub_any_instance not available in minitest
    skip 'Requires mocha or similar mocking library for stub_any_instance'
  end
end
