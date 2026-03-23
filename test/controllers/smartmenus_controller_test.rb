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

  test 'GET show succeeds anonymously via slug' do
    smartmenu = smartmenus(:one)
    get smartmenu_path(smartmenu.slug)
    assert_response :success
  end

  test 'GET new redirects unauthenticated' do
    get new_smartmenu_path
    assert_redirected_to new_user_session_path
  end
end
