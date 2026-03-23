# frozen_string_literal: true

require 'test_helper'

class RestaurantClaimRequestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET new succeeds anonymously' do
    get new_restaurant_claim_request_path(@restaurant)
    assert_response :success
  end

  test 'GET submitted succeeds' do
    get submitted_restaurant_claim_requests_path(@restaurant)
    assert_response :success
  end

  test 'POST create with valid params redirects to submitted' do
    post restaurant_claim_requests_path(@restaurant), params: {
      restaurant_claim_request: {
        claimant_name: 'John Owner',
        claimant_email: 'john@example.com',
        claimant_phone: '0851234567',
        message: 'I own this restaurant',
      },
    }
    assert_redirected_to submitted_restaurant_claim_requests_path(@restaurant)
  end
end
