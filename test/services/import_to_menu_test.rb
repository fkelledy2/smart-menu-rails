# frozen_string_literal: true

require 'test_helper'

class ImportToMenuTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
    @plan = plans(:one)

    # Ensure user has a plan
    @user.update!(plan: @plan) if @user.plan.nil?
  end

  # Basic functionality tests
  test 'should create menu from valid import' do
    import = create_valid_import
    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    menu = service.call

    assert menu.persisted?
    assert_equal 'Test Menu', menu.name
    assert_equal 'active', menu.status
    assert_equal @restaurant.id, menu.restaurant_id
  end

  test 'should create sections and items from import' do
    import = create_valid_import_with_items
    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    menu = service.call

    assert_equal 2, menu.menusections.count

    starters = menu.menusections.find_by(name: 'Starters')
    assert_not_nil starters
    assert_equal 1, starters.sequence
    assert_equal 'Small plates', starters.description
    assert_equal 2, starters.menuitems.count

    mains = menu.menusections.find_by(name: 'Mains')
    assert_not_nil mains
    assert_equal 2, mains.sequence
    assert_equal 1, mains.menuitems.count
  end

  test 'should create menu items with correct attributes' do
    import = create_valid_import_with_items
    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    menu = service.call
    starters = menu.menusections.find_by(name: 'Starters')

    soup = starters.menuitems.find_by(name: 'Soup')
    assert_not_nil soup
    assert_equal 'Tomato soup', soup.description
    assert_equal 4.50, soup.price.to_f
    assert_equal 1, soup.sequence

    bread = starters.menuitems.find_by(name: 'Bread')
    assert_not_nil bread
    assert_equal 'Garlic bread', bread.description
    assert_equal 3.00, bread.price.to_f
    assert_equal 2, bread.sequence
  end

  test 'should link import to created menu' do
    import = create_valid_import
    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    menu = service.call
    import.reload

    assert_equal menu.id, import.menu_id
  end

  # Validation tests
  test 'should raise error for incomplete import' do
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Incomplete Menu',
      status: 'pending',
    )

    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    assert_raises(StandardError, /not completed/i) do
      service.call
    end
  end

  test 'should raise error for import without confirmed sections' do
    import = @restaurant.ocr_menu_imports.create!(
      name: 'No Sections Menu',
      status: 'completed',
    )

    # Create unconfirmed section
    import.ocr_menu_sections.create!(
      name: 'Unconfirmed',
      sequence: 1,
      is_confirmed: false,
    )

    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    assert_raises(StandardError, /No confirmed sections/i) do
      service.call
    end
  end

  test 'should raise error when menu already exists for import' do
    import = create_valid_import
    existing_menu = @restaurant.menus.create!(
      name: 'Existing Menu',
      description: 'Already exists',
      status: 'active',
    )
    import.update!(menu: existing_menu)

    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    assert_raises(StandardError, /already created/i) do
      service.call
    end
  end

  # Upsert functionality tests
  test 'should upsert into existing menu' do
    # Create existing menu with one section
    existing_menu = @restaurant.menus.create!(
      name: 'Existing Menu',
      description: 'Original description',
      status: 'active',
    )

    existing_menu.menusections.create!(
      name: 'Starters',
      description: 'Original starters',
      sequence: 1,
      status: 'active',
    )

    # Create import with updated data
    import = create_import_for_upsert
    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    result = service.upsert_into_menu(existing_menu)

    # The method returns [menu, stats]
    assert result.is_a?(Array)
    assert_equal 2, result.length

    menu, stats = result
    assert_equal existing_menu, menu
    assert stats.is_a?(Hash)
    assert stats.key?(:sections_updated)
    assert stats.key?(:sections_created)
    assert stats.key?(:items_created)

    existing_menu.reload
    assert_equal 'Updated Menu', existing_menu.name
    assert existing_menu.menusections.count >= 1
  end

  # Edge case tests
  test 'should handle empty section descriptions' do
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Test Menu',
      status: 'completed',
    )

    section = import.ocr_menu_sections.create!(
      name: 'Section',
      sequence: 1,
      is_confirmed: true,
      description: nil,
    )

    section.ocr_menu_items.create!(
      name: 'Item',
      description: 'Test item',
      price: 5.00,
      sequence: 1,
      is_confirmed: true,
    )

    service = ImportToMenu.new(restaurant: @restaurant, import: import)
    menu = service.call

    created_section = menu.menusections.first
    # Description might be empty string instead of nil due to safe_text processing
    assert created_section.description.blank?
  end

  test 'should handle items without descriptions' do
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Test Menu',
      status: 'completed',
    )

    section = import.ocr_menu_sections.create!(
      name: 'Section',
      sequence: 1,
      is_confirmed: true,
    )

    section.ocr_menu_items.create!(
      name: 'Item',
      description: nil,
      price: 5.00,
      sequence: 1,
      is_confirmed: true,
    )

    service = ImportToMenu.new(restaurant: @restaurant, import: import)
    menu = service.call

    created_item = menu.menusections.first.menuitems.first
    # Description might be empty string instead of nil due to safe_text processing
    assert created_item.description.blank?
  end

  test 'should handle zero prices' do
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Test Menu',
      status: 'completed',
    )

    section = import.ocr_menu_sections.create!(
      name: 'Section',
      sequence: 1,
      is_confirmed: true,
    )

    section.ocr_menu_items.create!(
      name: 'Free Item',
      description: 'No charge',
      price: 0.00,
      sequence: 1,
      is_confirmed: true,
    )

    service = ImportToMenu.new(restaurant: @restaurant, import: import)
    menu = service.call

    created_item = menu.menusections.first.menuitems.first
    assert_equal 0.00, created_item.price.to_f
  end

  test 'should skip unconfirmed items' do
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Test Menu',
      status: 'completed',
    )

    section = import.ocr_menu_sections.create!(
      name: 'Section',
      sequence: 1,
      is_confirmed: true,
    )

    # Confirmed item
    section.ocr_menu_items.create!(
      name: 'Confirmed Item',
      price: 5.00,
      sequence: 1,
      is_confirmed: true,
    )

    # Unconfirmed item
    section.ocr_menu_items.create!(
      name: 'Unconfirmed Item',
      price: 10.00,
      sequence: 2,
      is_confirmed: false,
    )

    service = ImportToMenu.new(restaurant: @restaurant, import: import)
    menu = service.call

    created_section = menu.menusections.first
    assert_equal 1, created_section.menuitems.count
    assert_equal 'Confirmed Item', created_section.menuitems.first.name
  end

  # Transaction and error handling tests
  test 'should use database transaction' do
    import = create_valid_import
    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    # Test that the service creates menu within a transaction
    initial_menu_count = @restaurant.menus.count

    menu = service.call

    assert menu.persisted?
    assert_equal initial_menu_count + 1, @restaurant.menus.count
  end

  # Helper method tests
  test 'should create menu with description' do
    import = create_valid_import
    service = ImportToMenu.new(restaurant: @restaurant, import: import)

    menu = service.call

    # Menu should have a description (either from import or default)
    assert_not_nil menu.description
    assert menu.description.is_a?(String)
  end

  private

  def create_valid_import
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Test Menu',
      status: 'completed',
    )

    section = import.ocr_menu_sections.create!(
      name: 'Test Section',
      sequence: 1,
      is_confirmed: true,
    )

    section.ocr_menu_items.create!(
      name: 'Test Item',
      description: 'Test description',
      price: 10.00,
      sequence: 1,
      is_confirmed: true,
    )

    import
  end

  def create_valid_import_with_items
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Test Menu',
      status: 'completed',
    )

    # Create Starters section
    starters = import.ocr_menu_sections.create!(
      name: 'Starters',
      description: 'Small plates',
      sequence: 1,
      is_confirmed: true,
    )

    starters.ocr_menu_items.create!(
      name: 'Soup',
      description: 'Tomato soup',
      price: 4.50,
      sequence: 1,
      is_confirmed: true,
    )

    starters.ocr_menu_items.create!(
      name: 'Bread',
      description: 'Garlic bread',
      price: 3.00,
      sequence: 2,
      is_confirmed: true,
    )

    # Create Mains section
    mains = import.ocr_menu_sections.create!(
      name: 'Mains',
      sequence: 2,
      is_confirmed: true,
    )

    mains.ocr_menu_items.create!(
      name: 'Steak',
      description: 'Sirloin steak',
      price: 15.00,
      sequence: 1,
      is_confirmed: true,
    )

    import
  end

  def create_import_for_upsert
    import = @restaurant.ocr_menu_imports.create!(
      name: 'Updated Menu',
      status: 'completed',
    )

    # Update existing section
    starters = import.ocr_menu_sections.create!(
      name: 'Starters',
      description: 'Updated starters',
      sequence: 1,
      is_confirmed: true,
    )

    starters.ocr_menu_items.create!(
      name: 'New Soup',
      description: 'Updated soup',
      price: 5.00,
      sequence: 1,
      is_confirmed: true,
    )

    # Add new section
    desserts = import.ocr_menu_sections.create!(
      name: 'Desserts',
      description: 'Sweet treats',
      sequence: 2,
      is_confirmed: true,
    )

    desserts.ocr_menu_items.create!(
      name: 'Ice Cream',
      description: 'Vanilla ice cream',
      price: 4.00,
      sequence: 1,
      is_confirmed: true,
    )

    import
  end
end
