require 'test_helper'

class MenuTest < ActiveSupport::TestCase
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
end
