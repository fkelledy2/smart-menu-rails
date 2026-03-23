# frozen_string_literal: true

require 'test_helper'

class RestaurantRemovalRequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET new succeeds anonymously' do
    get new_restaurant_removal_request_path(@restaurant)
    assert_response :success
  end

  test 'GET submitted succeeds' do
    get submitted_restaurant_removal_requests_path(@restaurant)
    assert_response :success
  end

  test 'POST create with valid params redirects to submitted' do
    post restaurant_removal_requests_path(@restaurant), params: {
      restaurant_removal_request: {
        requested_by_email: 'owner@example.com',
        reason: 'This is my restaurant and I want it removed',
      },
    }
    assert_redirected_to submitted_restaurant_removal_requests_path(@restaurant)
  end
end
