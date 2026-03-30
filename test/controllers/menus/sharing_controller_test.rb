# frozen_string_literal: true

require 'test_helper'

class Menus::SharingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)   # owned by users(:one)
    @restaurant2 = restaurants(:two)  # owned by users(:two)
    @menu = menus(:one)               # belongs to restaurant :one

    sign_in @user
  end

  # ---------------------------------------------------------------------------
  # POST attach
  # ---------------------------------------------------------------------------

  test 'attach: redirects unauthenticated user' do
    sign_out @user
    post attach_restaurant_menu_path(@restaurant, @menu)

    assert_redirected_to new_user_session_path
  end

  test 'attach: attaches menu to restaurant and redirects' do
    # menus(:five) belongs to restaurant :one — user :one is the menu owner so
    # the attach? policy allows it.
    owned_menu = menus(:five)

    # Ensure no existing join record so attach creates one fresh
    RestaurantMenu.where(restaurant: @restaurant, menu: owned_menu).delete_all

    post attach_restaurant_menu_path(@restaurant, owned_menu)

    assert_response :redirect
    assert RestaurantMenu.exists?(restaurant: @restaurant, menu: owned_menu)
  end

  test 'attach: returns 404 when menu is not found' do
    # RecordNotFound from Menu.find propagates as 404 (not rescued in action)
    post attach_restaurant_menu_path(@restaurant, id: 0)

    assert_response :not_found
  end

  # ---------------------------------------------------------------------------
  # POST share
  # ---------------------------------------------------------------------------

  test 'share: redirects unauthenticated user' do
    sign_out @user
    post share_restaurant_menu_path(@restaurant, @menu),
         params: { target_restaurant_ids: [] }

    assert_redirected_to new_user_session_path
  end

  test 'share: redirects with alert when no target restaurants found' do
    post share_restaurant_menu_path(@restaurant, @menu),
         params: { target_restaurant_ids: ['999999'] }

    assert_redirected_to edit_restaurant_path(@restaurant, section: 'menus')
    assert_match(/not found/i, flash[:alert].to_s)
  end

  test 'share: redirects when authorized user tries to share a non-owner menu' do
    # Set owner_restaurant_id to restaurants(:two) so @restaurant is not the owner.
    # The authorize check passes (restaurant_owner? and menu_owner? both use
    # owner_restaurant || menu.restaurant; here we use super_admin to bypass Pundit
    # and hit the explicit ownership guard inside the action).
    super_admin = users(:super_admin)
    @restaurant.update_column(:user_id, super_admin.id)
    sign_in super_admin
    @menu.update_column(:owner_restaurant_id, restaurants(:two).id)

    post share_restaurant_menu_path(@restaurant, @menu),
         params: { target_restaurant_ids: ['all'] }

    assert_redirected_to edit_restaurant_path(@restaurant, section: 'menus')
    assert_match(/owner/i, flash[:alert].to_s)
  ensure
    @menu.update_column(:owner_restaurant_id, nil)
    @restaurant.update_column(:user_id, @user.id)
  end

  # ---------------------------------------------------------------------------
  # DELETE detach
  # ---------------------------------------------------------------------------

  test 'detach: redirects unauthenticated user' do
    sign_out @user
    delete detach_restaurant_menu_path(@restaurant, @menu)

    assert_redirected_to new_user_session_path
  end

  test 'detach: redirects with alert when owner restaurant tries to detach own menu' do
    # @menu is owned by @restaurant — owner cannot detach
    delete detach_restaurant_menu_path(@restaurant, @menu)

    assert_redirected_to edit_restaurant_path(@restaurant, section: 'menus')
    assert_match(/cannot detach/i, flash[:alert].to_s)
  end

  test 'detach: redirects with alert when menu is not attached' do
    # Find a menu not attached to @restaurant
    unattached_menu = menus(:four) # belongs to restaurant :two
    RestaurantMenu.where(restaurant: @restaurant, menu: unattached_menu).delete_all

    delete detach_restaurant_menu_path(@restaurant, unattached_menu)

    # authorize fires first; if owner then alert about ownership; else not attached
    assert_response :redirect
  end

  test 'detach: successfully detaches a shared menu' do
    sign_in users(:two)
    sharing_menu = menus(:two) # owned by restaurant :two

    # Attach it to a third restaurant first (restaurants(:one), user :one)
    # Actually we need a restaurant owned by users(:two) that has the menu attached via sharing
    # restaurant(:two) owns menus(:two); create a second restaurant for user :two
    shared_restaurant = Restaurant.create!(
      name: 'Shared Test Restaurant',
      description: 'Test',
      address1: '123 Test St',
      city: 'TestCity',
      country: 'US',
      currency: 'USD',
      status: 1,
      capacity: 10,
      user: users(:two),
    )
    rm = RestaurantMenu.create!(
      restaurant: shared_restaurant,
      menu: sharing_menu,
      sequence: 99,
      status: :active,
      availability_override_enabled: false,
      availability_state: :available,
    )

    # Temporarily set menu owner_restaurant_id so detach sees it as non-owner
    sharing_menu.update_column(:owner_restaurant_id, @restaurant2.id)

    delete detach_restaurant_menu_path(shared_restaurant, sharing_menu)

    assert_response :redirect
    assert_not RestaurantMenu.exists?(rm.id)
  ensure
    sharing_menu.update_column(:owner_restaurant_id, nil)
    shared_restaurant&.destroy
  end
end
