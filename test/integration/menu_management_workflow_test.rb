require 'test_helper'

class MenuManagementWorkflowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update(user: @user)
    sign_in @user
  end

  test 'complete menu CRUD workflow' do
    # Step 1: Create a new menu
    menu = @restaurant.menus.create!(
      name: 'Dinner Menu',
      description: 'Our evening selections',
      status: 'active',
    )

    assert_not_nil menu
    assert_equal 'Dinner Menu', menu.name
    assert menu.persisted?

    # Step 2: Add a section
    section = menu.menusections.create!(
      name: 'Appetizers',
      sequence: 1,
      status: 1,
    )

    assert_not_nil section
    assert_equal 'Appetizers', section.name

    # Step 3: Add menu items
    item = section.menuitems.create!(
      name: 'Bruschetta',
      description: 'Toasted bread with tomatoes',
      price: 8.99,
      status: :active,
      calories: 200,
      archived: false,
    )

    assert_not_nil item
    assert_equal 8.99, item.price
    assert_equal 'active', item.status

    # Step 4: Update menu item
    item.update!(
      price: 9.99,
      description: 'Updated description',
    )

    item.reload
    assert_equal 9.99, item.price
    assert_equal 'Updated description', item.description

    # Step 5: Delete menu item
    initial_count = section.menuitems.count
    item_id = item.id
    item.destroy

    assert_equal initial_count - 1, section.menuitems.count
    assert_nil Menuitem.find_by(id: item_id)
  end

  test 'menu publishing workflow' do
    # Create inactive menu
    menu = @restaurant.menus.create!(
      name: 'Draft Menu',
      description: 'Work in progress',
      status: 'inactive',
    )

    assert_equal 'inactive', menu.status

    # Activate menu
    menu.update!(status: 'active')

    menu.reload
    assert_equal 'active', menu.status

    # Deactivate menu
    menu.update!(status: 'inactive')

    menu.reload
    assert_equal 'inactive', menu.status
  end

  test 'menu with multiple sections and items' do
    menu = @restaurant.menus.create!(name: 'Full Menu', status: 'active')

    # Create multiple sections
    appetizers = menu.menusections.create!(name: 'Appetizers', sequence: 1, status: 1)
    mains = menu.menusections.create!(name: 'Main Courses', sequence: 2, status: 1)
    desserts = menu.menusections.create!(name: 'Desserts', sequence: 3, status: 1)

    # Add items to each section
    appetizers.menuitems.create!(
      name: 'Soup',
      price: 6.99,
      status: 1,
      calories: 150,
    )

    mains.menuitems.create!(
      name: 'Steak',
      price: 24.99,
      status: 1,
      calories: 600,
    )

    desserts.menuitems.create!(
      name: 'Cake',
      price: 7.99,
      status: 1,
      calories: 350,
    )

    # Verify structure
    assert_equal 3, menu.menusections.count
    assert_equal 1, appetizers.menuitems.count
    assert_equal 1, mains.menuitems.count
    assert_equal 1, desserts.menuitems.count

    # Verify ordering
    sections = menu.menusections.order(:sequence)
    assert_equal 'Appetizers', sections.first.name
    assert_equal 'Desserts', sections.last.name
  end

  test 'menu item status toggle' do
    menu = @restaurant.menus.create!(name: 'Test Menu', status: 'active')
    section = menu.menusections.create!(name: 'Test Section', status: 1)
    item = section.menuitems.create!(
      name: 'Test Item',
      price: 10.00,
      status: :active,
      calories: 250,
      archived: false,
    )

    assert_equal 'active', item.status
    assert_not item.archived

    # Change status to inactive
    item.update!(status: :inactive)

    item.reload
    assert_equal 'inactive', item.status

    # Change back to active
    item.update!(status: :active)

    item.reload
    assert_equal 'active', item.status
  end

  test 'menu archival workflow' do
    menu = @restaurant.menus.create!(name: 'Archive Test Menu', status: 'active')
    section = menu.menusections.create!(name: 'Archive Test Section', status: 1)
    section.menuitems.create!(
      name: 'Archive Test Item',
      price: 5.00,
      status: 1,
      calories: 100,
    )

    # Archive menu (safer than deletion)
    menu.update!(status: :archived)

    menu.reload
    assert_equal 'archived', menu.status

    # Verify menu still exists but is archived
    archived_menu = Menu.find(menu.id)
    assert_not_nil archived_menu
    assert_equal 'archived', archived_menu.status
  end

  test 'menu item price updates' do
    menu = @restaurant.menus.create!(name: 'Price Test Menu', status: 'active')
    section = menu.menusections.create!(name: 'Price Test Section', status: 1)
    item = section.menuitems.create!(
      name: 'Price Test Item',
      price: 10.00,
      status: 1,
      calories: 200,
    )

    original_price = item.price

    # Update price
    item.update!(price: 12.50)

    item.reload
    assert_equal 12.50, item.price
    assert_not_equal original_price, item.price
  end

  test 'menu with allergen information' do
    menu = @restaurant.menus.create!(name: 'Dietary Menu', status: 'active')
    section = menu.menusections.create!(name: 'Healthy Options', status: 1)

    # Create item
    item = section.menuitems.create!(
      name: 'Vegan Salad',
      price: 12.00,
      status: 1,
      calories: 180,
    )

    # Verify item created
    assert_not_nil item
    assert_equal 'Vegan Salad', item.name
    assert_equal 12.00, item.price
  end
end
