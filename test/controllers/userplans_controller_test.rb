# frozen_string_literal: true

require 'test_helper'

class UserplansControllerTest < ActionDispatch::IntegrationTest
  test 'GET index redirects unauthenticated' do
    get userplans_path
    assert_redirected_to new_user_session_path
  end

  test 'GET index succeeds for authenticated user' do
    sign_in users(:one)
    get userplans_path
    assert_response :success
  end

  test 'GET show redirects unauthenticated' do
    get userplan_path(userplans(:one))
    assert_redirected_to new_user_session_path
  end

  test 'GET show succeeds for plan owner' do
    sign_in users(:one)
    get userplan_path(userplans(:one))
    assert_response :success
  end

  test 'GET new redirects unauthenticated' do
    get new_userplan_path
    assert_redirected_to new_user_session_path
  end

  test 'GET new succeeds for authenticated user' do
    sign_in users(:one)
    get new_userplan_path
    assert_response :success
  end
end
