require 'test_helper'

class EnforceRestaurantPlanLimitJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @plan = plans(:one)

    @user.update!(plan: @plan) if @user.plan != @plan
    
    # Deactivate any existing active restaurants from fixtures to start clean
    @user.restaurants.where(archived: false, status: Restaurant.statuses[:active]).update_all(status: Restaurant.statuses[:inactive])
  end

  test 'keeps most recently created active restaurants up to plan limit and deactivates the rest' do
    limit = @plan.locations
    assert_equal 1, limit

    old_restaurant = Restaurant.create!(
      user: @user,
      name: 'Old Active',
      status: :active,
      currency: 'USD',
    )

    newest_restaurant = Restaurant.create!(
      user: @user,
      name: 'Newest Active',
      status: :active,
      currency: 'USD',
    )

    old_restaurant.update_columns(created_at: 2.days.ago, updated_at: 2.days.ago)
    newest_restaurant.update_columns(created_at: 1.minute.ago, updated_at: 1.minute.ago)

    EnforceRestaurantPlanLimitJob.perform_now(user_id: @user.id)

    assert_equal 1, @user.restaurants.where(archived: false, status: Restaurant.statuses[:active]).count

    newest_restaurant.reload
    old_restaurant.reload

    assert_equal 'active', newest_restaurant.status
    assert_equal 'inactive', old_restaurant.status

    old_restaurant.destroy
    newest_restaurant.destroy
  end

  test 'does nothing when plan allows unlimited locations' do
    @plan.update!(locations: -1)

    r1 = Restaurant.create!(user: @user, name: 'A', status: :active, currency: 'USD')
    r2 = Restaurant.create!(user: @user, name: 'B', status: :active, currency: 'USD')

    EnforceRestaurantPlanLimitJob.perform_now(user_id: @user.id)

    assert_equal 2, @user.restaurants.where(archived: false, status: Restaurant.statuses[:active]).count

    r1.destroy
    r2.destroy
  end
end
