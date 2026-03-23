# frozen_string_literal: true

require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'GET index redirects unauthenticated users' do
    get notifications_path
    assert_redirected_to new_user_session_path
  end
end
