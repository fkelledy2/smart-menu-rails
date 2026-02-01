require 'test_helper'

class EnforceRestaurantMenuPlanLimitJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @plan = plans(:one)

    @user.update!(plan: @plan) if @user.plan != @plan
  end

  test 'keeps most recently imported menus up to plan limit and deactivates the rest' do
    limit = @plan.menusperlocation
    assert_equal 1, limit

    restaurant = Restaurant.create!(
      user: @user,
      name: 'Menu Limit Test',
      status: :active,
      currency: 'USD',
    )

    old_menu = Menu.create!(restaurant: restaurant, name: 'Old Menu', status: :active, archived: false)
    new_menu = Menu.create!(restaurant: restaurant, name: 'New Menu', status: :active, archived: false)

    old_rm = RestaurantMenu.find_by!(restaurant: restaurant, menu: old_menu)
    new_rm = RestaurantMenu.find_by!(restaurant: restaurant, menu: new_menu)

    old_rm.update!(status: :active)
    new_rm.update!(status: :active)

    old_import = OcrMenuImport.create!(restaurant: restaurant, menu: old_menu, name: 'Old Import', status: 'completed')
    new_import = OcrMenuImport.create!(restaurant: restaurant, menu: new_menu, name: 'New Import', status: 'completed')

    old_import.update_columns(created_at: 2.days.ago, updated_at: 2.days.ago)
    new_import.update_columns(created_at: 1.minute.ago, updated_at: 1.minute.ago)

    EnforceRestaurantMenuPlanLimitJob.perform_now(restaurant_id: restaurant.id)

    old_rm.reload
    new_rm.reload

    assert_equal 'inactive', old_rm.status
    assert_equal 'active', new_rm.status
  end

  test 'does nothing when plan allows unlimited menus per location' do
    @plan.update!(menusperlocation: -1)

    restaurant = Restaurant.create!(
      user: @user,
      name: 'Unlimited Menu Limit Test',
      status: :active,
      currency: 'USD',
    )

    m1 = Menu.create!(restaurant: restaurant, name: 'A', status: :active, archived: false)
    m2 = Menu.create!(restaurant: restaurant, name: 'B', status: :active, archived: false)

    rm1 = RestaurantMenu.find_by!(restaurant: restaurant, menu: m1)
    rm2 = RestaurantMenu.find_by!(restaurant: restaurant, menu: m2)

    rm1.update!(status: :active)
    rm2.update!(status: :active)

    EnforceRestaurantMenuPlanLimitJob.perform_now(restaurant_id: restaurant.id)

    rm1.reload
    rm2.reload

    assert_equal 'active', rm1.status
    assert_equal 'active', rm2.status
  end
end
