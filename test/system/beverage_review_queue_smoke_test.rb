require 'application_system_test_case'

class BeverageReviewQueueSmokeTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user) if @restaurant.user != @user

    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test 'beverage review queue page loads' do
    visit beverage_review_queue_restaurant_path(@restaurant)
    assert_text 'Beverage Review Queue'
  end
end
