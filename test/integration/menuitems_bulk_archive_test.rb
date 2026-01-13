require 'test_helper'

class MenuitemsBulkArchiveTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user)
    sign_in @user

    Rails.cache.clear
  end

  test 'bulk archive removes items from menu edit items list' do
    menu = @restaurant.menus.create!(name: 'Bulk Archive Menu', status: 'active')
    section = menu.menusections.create!(name: 'Section', sequence: 1, status: 1)

    item_to_archive = section.menuitems.create!(
      name: 'Archive Me',
      description: 'test',
      price: 1.0,
      status: :active,
      calories: 100,
      archived: false,
      sequence: 1,
    )

    item_to_keep = section.menuitems.create!(
      name: 'Keep Me',
      description: 'test',
      price: 2.0,
      status: :active,
      calories: 100,
      archived: false,
      sequence: 2,
    )

    # Prime the page and cache
    get edit_restaurant_menu_path(@restaurant, menu, section: 'items')
    assert_response :success
    assert_includes response.body, item_to_archive.name
    assert_includes response.body, item_to_keep.name

    # Perform bulk archive
    patch bulk_update_restaurant_menu_menuitems_path(@restaurant, menu), params: {
      menuitem_ids: [item_to_archive.id],
      operation: 'archive',
      value: '1',
    }
    assert_response :redirect

    item_to_archive.reload
    assert_equal 'archived', item_to_archive.status
    assert_equal true, item_to_archive.archived

    # Archived item should no longer appear in items list
    Rails.cache.clear
    get edit_restaurant_menu_path(@restaurant, menu, section: 'items')
    assert_response :success
    assert_not_includes response.body, item_to_archive.name
    assert_includes response.body, item_to_keep.name
  end
end
