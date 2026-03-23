require 'test_helper'

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test 'GET /announcements returns success' do
    get announcements_path
    assert_response :success
  end

  test 'GET /announcements redirects unauthenticated users' do
    sign_out @user
    get announcements_path
    assert_redirected_to new_user_session_path
  end

  test 'GET /announcements updates announcements_last_read_at' do
    original = @user.announcements_last_read_at
    get announcements_path
    assert_response :success
    @user.reload
    assert @user.announcements_last_read_at >= (original || Time.zone.at(0))
  end
end
