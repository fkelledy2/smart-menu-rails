require 'test_helper'

class MenuitemsBulkArchiveTest < ActionDispatch::IntegrationTest
  setup do
    @previous_allow_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false

    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user)
    @user.reload
    sign_in @user

    Rails.cache.clear
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @previous_allow_forgery_protection
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
    assert response.body.include?("data-testid=\"menu-item-#{item_to_archive.id}\"")
    assert response.body.include?("data-testid=\"menu-item-#{item_to_keep.id}\"")

    # Perform bulk archive
    patch bulk_update_restaurant_menu_menuitems_path(@restaurant, menu), params: {
      menuitem_ids: [item_to_archive.id],
      operation: 'archive',
      value: '1',
    }
    assert_response :redirect

    assert_redirected_to edit_restaurant_menu_path(@restaurant, menu, section: 'items'),
                         "redirected_to=#{response.location} alert=#{flash[:alert].inspect} notice=#{flash[:notice].inspect}"
    assert_nil flash[:alert]

    Menuitem.on_primary { item_to_archive.reload }
    assert_equal 'archived', item_to_archive.status
    assert_equal true, item_to_archive.archived

    # Archived item should no longer appear in items list
    Rails.cache.clear
    get edit_restaurant_menu_path(@restaurant, menu, section: 'items')
    assert_response :success
    assert !response.body.include?("data-testid=\"menu-item-#{item_to_archive.id}\""),
           'Archived item row should not appear in the items list'
    assert response.body.include?("data-testid=\"menu-item-#{item_to_keep.id}\"")
  end
end
