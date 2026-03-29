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

  # ---------------------------------------------------------------------------
  # Theme — PATCH update with theme param
  # ---------------------------------------------------------------------------

  test 'PATCH update with valid theme saves the new theme' do
    sign_in users(:one)
    sm = smartmenus(:one)
    patch smartmenu_path(sm.slug), params: { smartmenu: { theme: 'rustic' } }
    assert_equal 'rustic', sm.reload.theme
  end

  test 'PATCH update with invalid theme returns unprocessable' do
    sign_in users(:one)
    sm = smartmenus(:one)
    patch smartmenu_path(sm.slug), params: { smartmenu: { theme: 'neon' } }
    assert_response :unprocessable_content
  end

  test 'PATCH update with valid theme calls ThemeCacheBuster' do
    sign_in users(:one)
    sm = smartmenus(:one)
    buster_called = false

    Smartmenus::ThemeCacheBuster.stub(:new, lambda { |_|
      stub_b = Object.new
      stub_b.define_singleton_method(:call) { buster_called = true }
      stub_b
    },) do
      patch smartmenu_path(sm.slug), params: { smartmenu: { theme: 'elegant' } }
    end

    assert buster_called
  end

  # ---------------------------------------------------------------------------
  # Preview mode — signed token
  # ---------------------------------------------------------------------------

  test 'staff preview token sets @staff_view_mode true and renders back-pill' do
    sign_in users(:one)
    sm    = smartmenus(:one)
    token = SmartmenuPreviewToken.generate(mode: :staff, menu_id: sm.menu_id)

    get table_link_path(public_token: sm.public_token, preview: token)

    assert_response :success
    assert_select '[data-testid="preview-back-pill"]', count: 1
    assert_select '[data-testid="staff-mode-indicator"]', count: 0
  end

  test 'customer preview token sets @staff_view_mode false and renders no back-pill' do
    sign_in users(:one)
    sm    = smartmenus(:one)
    token = SmartmenuPreviewToken.generate(mode: :customer, menu_id: sm.menu_id)

    get table_link_path(public_token: sm.public_token, preview: token)

    assert_response :success
    assert_select '[data-testid="preview-back-pill"]', count: 0
    assert_select '[data-testid="staff-mode-indicator"]', count: 0
  end

  test 'no preview token renders customer view with no indicator or back-pill' do
    sign_in users(:one)
    sm = smartmenus(:one)

    get table_link_path(public_token: sm.public_token)

    assert_response :success
    assert_select '[data-testid="staff-mode-indicator"]', count: 0
    assert_select '[data-testid="preview-back-pill"]', count: 0
  end

  test 'expired preview token falls back silently to customer view' do
    sign_in users(:one)
    sm    = smartmenus(:one)
    token = SmartmenuPreviewToken.generate(mode: :staff, menu_id: sm.menu_id)

    travel_to(SmartmenuPreviewToken::TTL.from_now + 1.second) do
      get table_link_path(public_token: sm.public_token, preview: token)
    end

    assert_response :success
    assert_select '[data-testid="preview-back-pill"]', count: 0
  end

  test 'tampered preview token falls back silently to customer view' do
    sign_in users(:one)
    sm = smartmenus(:one)

    get table_link_path(public_token: sm.public_token, preview: 'tampered-garbage')

    assert_response :success
    assert_select '[data-testid="preview-back-pill"]', count: 0
  end

  test 'legacy ?view=staff param no longer activates staff mode' do
    sign_in users(:one)
    sm = smartmenus(:one)

    get table_link_path(public_token: sm.public_token, view: 'staff')

    assert_response :success
    assert_select '[data-testid="preview-back-pill"]', count: 0
    assert_select '[data-testid="staff-mode-indicator"]', count: 0
  end

  # ---------------------------------------------------------------------------
  # Theme — GET preview redirect
  # ---------------------------------------------------------------------------

  test 'GET preview redirects authenticated owner to token URL' do
    sign_in users(:one)
    sm = smartmenus(:one)
    get preview_smartmenu_path(sm.slug)
    assert_redirected_to table_link_url(public_token: sm.public_token)
  end

  test 'GET preview redirects unauthenticated user to sign in' do
    sm = smartmenus(:one)
    get preview_smartmenu_path(sm.slug)
    assert_redirected_to new_user_session_path
  end
end
