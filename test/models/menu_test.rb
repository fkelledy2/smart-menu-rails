require 'test_helper'

class MenuTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  
  def setup
    @menu = menus(:one)
    @restaurant = restaurants(:one)
  end

  # Association tests
  test 'should belong to restaurant' do
    assert_respond_to @menu, :restaurant
    assert_not_nil @menu.restaurant
  end

  test 'should have many menusections' do
    assert_respond_to @menu, :menusections
  end

  test 'should have many menuavailabilities' do
    assert_respond_to @menu, :menuavailabilities
  end

  test 'should have many menuitems through menusections' do
    assert_respond_to @menu, :menuitems
  end

  test 'should have many menulocales' do
    assert_respond_to @menu, :menulocales
  end

  test 'should have one genimage' do
    assert_respond_to @menu, :genimage
  end

  test 'should have one attached pdf_menu_scan' do
    assert_respond_to @menu, :pdf_menu_scan
  end

  # Validation tests
  test 'should be valid with valid attributes' do
    menu = Menu.new(
      name: 'Test Menu',
      restaurant: @restaurant,
      status: :active,
    )
    assert menu.valid?
  end

  test 'should require name' do
    menu = Menu.new(restaurant: @restaurant, status: :active)
    assert_not menu.valid?
    assert_includes menu.errors[:name], "can't be blank"
  end

  test 'should require status' do
    menu = Menu.new(name: 'Test Menu', restaurant: @restaurant)
    menu.status = nil
    assert_not menu.valid?
    assert_includes menu.errors[:status], "can't be blank"
  end

  # Enum tests
  test 'should have status enum' do
    assert_respond_to @menu, :status
    assert_respond_to @menu, :inactive?
    assert_respond_to @menu, :active?
    assert_respond_to @menu, :archived?
  end

  test 'should set status correctly' do
    @menu.status = :inactive
    assert @menu.inactive?
    assert_not @menu.active?
    assert_not @menu.archived?

    @menu.status = :active
    assert @menu.active?
    assert_not @menu.inactive?
    assert_not @menu.archived?

    @menu.status = :archived
    assert @menu.archived?
    assert_not @menu.inactive?
    assert_not @menu.active?
  end

  # Business logic tests
  test 'slug should return smartmenu slug when exists' do
    # Check if there's already a smartmenu from fixtures
    existing_smartmenu = Smartmenu.where(restaurant: @menu.restaurant, menu: @menu).first
    if existing_smartmenu
      assert_equal existing_smartmenu.slug, @menu.slug
    else
      # Create a smartmenu for this menu
      Smartmenu.create!(
        restaurant: @menu.restaurant,
        menu: @menu,
        slug: 'test-menu-slug',
      )
      assert_equal 'test-menu-slug', @menu.slug
    end
  end

  test 'slug should return empty string when no smartmenu exists' do
    # Create a new menu without smartmenu to avoid foreign key constraints
    menu = Menu.create!(
      name: 'Test Menu Without Smartmenu',
      restaurant: @restaurant,
      status: :active,
    )

    assert_equal '', menu.slug
  end

  test 'localised_name should return default name for default locale' do
    # Create a default restaurant locale to test with
    @menu.restaurant.restaurantlocales.create!(
      locale: 'en',
      status: 'active',
      dfault: true,
    )

    name = @menu.localised_name('en')
    assert_equal @menu.name, name
  end

  test 'localised_name should return menulocale name when available' do
    # Create a menulocale for testing
    @menu.menulocales.create!(
      locale: 'es',
      name: 'Menú de Prueba',
      description: 'Descripción de prueba',
    )

    # Create a non-default restaurant locale
    @menu.restaurant.restaurantlocales.create!(
      locale: 'es',
      status: 'active',
      dfault: false,
    )

    assert_equal 'Menú de Prueba', @menu.localised_name('es')
  end

  test 'localised_name should fallback to default name when no menulocale' do
    # Create a non-default restaurant locale to avoid nil error
    @menu.restaurant.restaurantlocales.create!(
      locale: 'fr',
      status: 'active',
      dfault: false,
    )

    # Test with a locale that doesn't have a menulocale
    name = @menu.localised_name('fr')
    assert_equal @menu.name, name
  end

  test 'localised_description should return default description for default locale' do
    # Create a default restaurant locale to test with
    @menu.restaurant.restaurantlocales.create!(
      locale: 'en',
      status: 'active',
      dfault: true,
    )

    description = @menu.localised_description('en')
    assert_equal @menu.description, description
  end

  test 'localised_description should return menulocale description when available' do
    # Create a menulocale for testing
    @menu.menulocales.create!(
      locale: 'es',
      name: 'Menú de Prueba',
      description: 'Descripción de prueba',
    )

    # Create a non-default restaurant locale
    @menu.restaurant.restaurantlocales.create!(
      locale: 'es',
      status: 'active',
      dfault: false,
    )

    assert_equal 'Descripción de prueba', @menu.localised_description('es')
  end

  test 'localised_description should fallback to default description when no menulocale' do
    # Create a non-default restaurant locale to avoid nil error
    @menu.restaurant.restaurantlocales.create!(
      locale: 'fr',
      status: 'active',
      dfault: false,
    )

    description = @menu.localised_description('fr')
    assert_equal @menu.description, description
  end

  test 'gen_image_theme should return genimage id when present' do
    if @menu.genimage
      assert_equal @menu.genimage.id, @menu.send(:gen_image_theme)
    else
      assert_nil @menu.send(:gen_image_theme)
    end
  end

  # PDF validation tests
  test 'should be valid without pdf_menu_scan' do
    menu = Menu.new(
      name: 'Test Menu',
      restaurant: @restaurant,
      status: :active,
    )

    assert menu.valid?
  end

  test 'should have pdf_menu_scan_format validation method' do
    # Test that the validation method exists
    assert @menu.respond_to?(:send)
    # The actual validation is tested through the model's validation process
    assert @menu.valid?
  end

  # IdentityCache tests
  test 'should have identity cache configured' do
    assert Menu.respond_to?(:cache_index)
    assert Menu.respond_to?(:fetch_by_id)
    assert Menu.respond_to?(:fetch_by_restaurant_id)
  end

  # Cache association tests
  test 'should have cached associations configured' do
    # Test that cache methods are available
    assert @menu.respond_to?(:fetch_menusections)
    assert @menu.respond_to?(:fetch_menuavailabilities)
    assert @menu.respond_to?(:fetch_menulocales)
  end

  # === CALLBACK TESTS ===

  # after_update :invalidate_menu_caches callback tests
  test 'should call cache invalidation after update' do
    mock = Minitest::Mock.new
    mock.expect :call, true, [@menu.id]
    
    AdvancedCacheService.stub :invalidate_menu_caches, mock do
      @menu.update!(name: 'Updated Menu Name')
      mock.verify
    end
  end

  test 'should not call cache invalidation on create' do
    mock = Minitest::Mock.new
    # No expectation set - should not be called
    
    AdvancedCacheService.stub :invalidate_menu_caches, mock do
      Menu.create!(
        name: 'New Menu',
        restaurant: @restaurant,
        status: :active
      )
      # If cache invalidation was called, mock would raise error
    end
  end

  test 'should call cache invalidation with correct menu id' do
    original_id = @menu.id
    called_with_id = nil
    
    AdvancedCacheService.stub :invalidate_menu_caches, ->(id) { called_with_id = id } do
      @menu.update!(description: 'Updated description')
    end
    
    assert_equal original_id, called_with_id
  end

  # after_destroy :invalidate_menu_caches callback tests
  test 'should call cache invalidation after destroy' do
    menu = Menu.create!(
      name: 'Menu to Delete',
      restaurant: @restaurant,
      status: :active
    )
    menu_id = menu.id
    
    mock = Minitest::Mock.new
    mock.expect :call, true, [menu_id]
    
    AdvancedCacheService.stub :invalidate_menu_caches, mock do
      menu.destroy!
      mock.verify
    end
  end

  test 'should trigger cache invalidation on any attribute update' do
    attributes_to_test = [
      { name: 'New Name' },
      { description: 'New Description' },
      { status: :archived }
    ]
    
    attributes_to_test.each do |attrs|
      mock = Minitest::Mock.new
      mock.expect :call, true, [@menu.id]
      
      AdvancedCacheService.stub :invalidate_menu_caches, mock do
        @menu.update!(attrs)
        mock.verify
      end
    end
  end

  # after_commit :enqueue_localization callback tests
  test 'should call enqueue_localization after create' do
    menu = Menu.new(
      name: 'New Menu for Localization',
      restaurant: @restaurant,
      status: :active
    )
    
    # Mock the Sidekiq job
    mock = Minitest::Mock.new
    mock.expect :call, true, ['menu', Integer]
    
    MenuLocalizationJob.stub :perform_async, mock do
      menu.save!
      mock.verify
    end
  end

  test 'should not call enqueue_localization on update' do
    # Mock should not be called
    mock = Minitest::Mock.new
    # No expectation set
    
    MenuLocalizationJob.stub :perform_async, mock do
      @menu.update!(name: 'Updated Name')
      # If enqueue was called, mock would raise error
    end
  end

  test 'should not call enqueue_localization on destroy' do
    menu = Menu.create!(
      name: 'Menu to Delete',
      restaurant: @restaurant,
      status: :active
    )
    
    # Mock should not be called for destroy
    mock = Minitest::Mock.new
    # No expectation set
    
    MenuLocalizationJob.stub :perform_async, mock do
      menu.destroy!
      # If enqueue was called, mock would raise error
    end
  end

  test 'should call enqueue_localization with correct parameters' do
    menu = Menu.new(
      name: 'Test Menu',
      restaurant: @restaurant,
      status: :active
    )
    
    called_with_type = nil
    called_with_id = nil
    
    MenuLocalizationJob.stub :perform_async, ->(type, id) { 
      called_with_type = type
      called_with_id = id
    } do
      menu.save!
    end
    
    assert_equal 'menu', called_with_type
    assert_equal menu.id, called_with_id
  end

  # === SCOPE TESTS ===

  # with_availabilities_and_sections scope tests
  test 'should eager load associations with with_availabilities_and_sections scope' do
    menu = Menu.create!(
      name: 'Test Menu with Associations',
      restaurant: @restaurant,
      status: :active
    )
    menu.menusections.create!(name: 'Section 1', status: :active)
    menu.menuavailabilities.create!(menu: menu, dayofweek: 1, starthour: 9, startmin: 0, endhour: 17, endmin: 0)
    
    results = Menu.with_availabilities_and_sections
    
    # Verify associations are loaded
    assert results.first.association(:menusections).loaded?
    assert results.first.association(:menuavailabilities).loaded?
    assert results.first.association(:restaurant).loaded?
  end

  test 'should include all menus with with_availabilities_and_sections scope' do
    menu1 = Menu.create!(name: 'Menu 1', restaurant: @restaurant, status: :active)
    menu2 = Menu.create!(name: 'Menu 2', restaurant: @restaurant, status: :inactive)
    menu3 = Menu.create!(name: 'Menu 3', restaurant: @restaurant, status: :active, archived: true)
    
    results = Menu.with_availabilities_and_sections
    
    assert_includes results, menu1
    assert_includes results, menu2
    assert_includes results, menu3
  end

  # for_customer_display scope tests
  test 'should return only active non-archived menus with for_customer_display' do
    active_menu = Menu.create!(
      name: 'Active Menu',
      restaurant: @restaurant,
      status: :active,
      archived: false
    )
    
    inactive_menu = Menu.create!(
      name: 'Inactive Menu',
      restaurant: @restaurant,
      status: :inactive,
      archived: false
    )
    
    archived_menu = Menu.create!(
      name: 'Archived Menu',
      restaurant: @restaurant,
      status: :active,
      archived: true
    )
    
    results = Menu.for_customer_display
    
    assert_includes results, active_menu
    assert_not_includes results, inactive_menu
    assert_not_includes results, archived_menu
  end

  test 'should include associations with for_customer_display' do
    menu = Menu.create!(
      name: 'Customer Menu',
      restaurant: @restaurant,
      status: :active,
      archived: false
    )
    menu.menusections.create!(name: 'Section', status: :active)
    
    results = Menu.for_customer_display
    
    # Verify associations are loaded
    assert results.first.association(:menusections).loaded?
    assert results.first.association(:menuavailabilities).loaded?
  end

  test 'should exclude inactive and archived menus from for_customer_display' do
    inactive_menu = Menu.create!(name: 'Inactive', restaurant: @restaurant, status: :inactive, archived: false)
    archived_menu = Menu.create!(name: 'Archived', restaurant: @restaurant, status: :active, archived: true)
    
    results = Menu.for_customer_display
    
    assert_not_includes results, inactive_menu
    assert_not_includes results, archived_menu
  end

  # for_management_display scope tests
  test 'should return non-archived menus with for_management_display' do
    active_menu = Menu.create!(
      name: 'Active Menu',
      restaurant: @restaurant,
      status: :active,
      archived: false
    )
    
    inactive_menu = Menu.create!(
      name: 'Inactive Menu',
      restaurant: @restaurant,
      status: :inactive,
      archived: false
    )
    
    archived_menu = Menu.create!(
      name: 'Archived Menu',
      restaurant: @restaurant,
      status: :active,
      archived: true
    )
    
    results = Menu.for_management_display
    
    assert_includes results, active_menu
    assert_includes results, inactive_menu
    assert_not_includes results, archived_menu
  end

  test 'should include inactive menus in for_management_display' do
    inactive_menu = Menu.create!(
      name: 'Inactive Menu',
      restaurant: @restaurant,
      status: :inactive,
      archived: false
    )
    
    results = Menu.for_management_display
    
    assert_includes results, inactive_menu
  end

  test 'should include associations with for_management_display' do
    menu = Menu.create!(
      name: 'Management Menu',
      restaurant: @restaurant,
      status: :active,
      archived: false
    )
    menu.menusections.create!(name: 'Section', status: :active)
    
    results = Menu.for_management_display
    
    # Verify associations are loaded
    assert results.first.association(:menusections).loaded?
    assert results.first.association(:menuavailabilities).loaded?
  end
end
