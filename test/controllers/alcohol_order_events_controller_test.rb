# frozen_string_literal: true

require 'test_helper'

class AlcoholOrderEventsControllerTest < ActionDispatch::IntegrationTest
  test 'GET index redirects unauthenticated' do
    get restaurant_alcohol_order_events_path(restaurants(:one))
    assert_redirected_to new_user_session_path
  end

  test 'GET index returns JSON for restaurant owner' do
    sign_in users(:one)
    get restaurant_alcohol_order_events_path(restaurants(:one)), as: :json
    assert_response :success
    assert_kind_of Array, response.parsed_body
  end
end
