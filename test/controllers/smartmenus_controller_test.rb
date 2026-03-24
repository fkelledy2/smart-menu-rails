# frozen_string_literal: true

require 'test_helper'

class SmartmenusControllerTest < ActionDispatch::IntegrationTest
  test 'GET index succeeds anonymously' do
    get smartmenus_path
    assert_response :success
  end

  test 'GET index succeeds for authenticated user' do
    sign_in users(:one)
    get smartmenus_path
    assert_response :success
  end

  test 'GET show via slug redirects permanently to token URL' do
    smartmenu = smartmenus(:one)
    get smartmenu_path(smartmenu.slug)
    assert_redirected_to table_link_path(public_token: smartmenu.public_token)
    assert_response :moved_permanently
  end

  test 'GET new redirects unauthenticated' do
    get new_smartmenu_path
    assert_redirected_to new_user_session_path
  end

  # ---------------------------------------------------------------------------
  # Token-based route: GET /t/:public_token
  # ---------------------------------------------------------------------------

  test 'GET /t/:public_token succeeds with a valid token' do
    sm = smartmenus(:one)
    get table_link_path(public_token: sm.public_token)
    assert_response :success
  end

  test 'GET /t/:invalid_token returns 404' do
    get table_link_path(public_token: 'z' * 64)
    assert_response :not_found
  end

  test 'GET /t/:public_token creates a DiningSession when tablesetting is present' do
    sm = smartmenus(:one)
    assert sm.tablesetting.present?, 'fixture :one must have a tablesetting'

    assert_difference 'DiningSession.count', 1 do
      get table_link_path(public_token: sm.public_token)
    end
  end

  test 'GET /t/:public_token stores dining_session_token in session cookie' do
    sm = smartmenus(:one)
    get table_link_path(public_token: sm.public_token)
    assert_not_nil session[:dining_session_token]
    assert_equal 64, session[:dining_session_token].length
  end

  test 'GET /t/:public_token does not create duplicate DiningSession on re-scan within TTL' do
    sm = smartmenus(:one)
    get table_link_path(public_token: sm.public_token)
    assert_difference 'DiningSession.count', 0 do
      get table_link_path(public_token: sm.public_token)
    end
  end

  test 'GET /t/:public_token creates new session when previous session has expired' do
    sm = smartmenus(:one)
    get table_link_path(public_token: sm.public_token)

    # Expire the session
    token = session[:dining_session_token]
    DiningSession.find_by(session_token: token).update!(expires_at: 1.minute.ago)

    assert_difference 'DiningSession.count', 1 do
      get table_link_path(public_token: sm.public_token)
    end
  end

  test 'GET /t/:public_token for smartmenu without tablesetting does not create DiningSession' do
    sm = smartmenus(:customer_menu) # no tablesetting in fixture
    assert_nil sm.tablesetting, 'customer_menu fixture must not have a tablesetting'

    assert_no_difference 'DiningSession.count' do
      get table_link_path(public_token: sm.public_token)
    end
    assert_response :success
  end
end
