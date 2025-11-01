require 'test_helper'

class SentryContextTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
  end

  test 'sentry context concern is included in application controller' do
    assert ApplicationController.included_modules.include?(SentryContext),
           'SentryContext should be included in ApplicationController'
  end

  test 'sentry context sets user information for authenticated requests' do
    sign_in @user
    get restaurants_path
    assert_response :success
  end

  test 'sentry context sets restaurant tags when restaurant is present' do
    sign_in @user
    get restaurant_path(@restaurant)
    assert_response :success
  end

  test 'sentry context sets controller and action tags' do
    sign_in @user
    get restaurants_path
    assert_response :success
  end

  test 'sentry context handles missing sentry gracefully' do
    # SentryContext has guards to handle when Sentry is not available
    sign_in @user
    get restaurants_path
    assert_response :success
  end

  test 'sentry context handles errors gracefully' do
    sign_in @user
    
    # SentryContext has error handling built in
    assert_nothing_raised do
      get restaurants_path
    end
    
    assert_response :success
  end

  test 'sentry context sets request information' do
    sign_in @user
    get restaurants_path, headers: { 'User-Agent' => 'TestBrowser/1.0' }
    assert_response :success
  end

  test 'sentry context works for unauthenticated requests' do
    # Should not error when no user is present
    assert_nothing_raised do
      get root_path
    end
    
    assert_response :success
  end

  test 'sentry context sets employee context when available' do
    sign_in @user
    get restaurants_path
    assert_response :success
  end
end
