require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest
  test 'GET / returns success for anonymous users' do
    get root_path
    assert_response :success
  end

  test 'GET / redirects signed-in users to restaurants' do
    sign_in users(:one)
    get root_path
    assert_redirected_to restaurants_path
  end

  test 'GET /terms returns success' do
    get terms_path
    assert_response :success
  end

  test 'GET /terms accepts JSON format' do
    get terms_path, as: :json
    assert_response :success
    json = response.parsed_body
    assert_equal 'success', json['status']
  end

  test 'GET /privacy returns success' do
    get privacy_path
    assert_response :success
  end

  test 'GET /privacy accepts JSON format' do
    get privacy_path, as: :json
    assert_response :success
    json = response.parsed_body
    assert_equal 'success', json['status']
  end
end
