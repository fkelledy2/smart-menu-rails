require "test_helper"

class PresenceServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @session_id = SecureRandom.uuid
  end
  
  test "user_online should create new session" do
    assert_difference('UserSession.count', 1) do
      session = PresenceService.user_online(@user, @session_id)
      assert session.present?
      assert_equal @user, session.user
      assert_equal 'active', session.status
    end
  end
  
  test "user_online should update existing session" do
    existing_session = UserSession.create!(
      user: @user,
      session_id: @session_id,
      status: 'idle'
    )
    
    assert_no_difference('UserSession.count') do
      session = PresenceService.user_online(@user, @session_id)
      assert_equal 'active', session.reload.status
    end
  end
  
  test "user_online with resource should set resource attributes" do
    session = PresenceService.user_online(
      @user,
      @session_id,
      resource_type: 'Menu',
      resource_id: 1
    )
    
    assert_equal 'Menu', session.resource_type
    assert_equal 1, session.resource_id
  end
  
  test "user_offline should mark session as offline" do
    session = UserSession.create!(
      user: @user,
      session_id: @session_id,
      status: 'active'
    )
    
    result = PresenceService.user_offline(@user, @session_id)
    assert_equal 'offline', result.reload.status
  end
  
  test "user_idle should mark session as idle" do
    session = UserSession.create!(
      user: @user,
      session_id: @session_id,
      status: 'active'
    )
    
    result = PresenceService.user_idle(@user, @session_id)
    assert_equal 'idle', result.reload.status
  end
  
  test "touch_activity should update session activity" do
    session = UserSession.create!(
      user: @user,
      session_id: @session_id,
      last_activity_at: 10.minutes.ago
    )
    
    PresenceService.touch_activity(@session_id)
    assert session.reload.last_activity_at > 1.minute.ago
  end
  
  test "get_active_users should return users for resource" do
    session1 = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      resource_type: 'Menu',
      resource_id: 1,
      status: 'active',
      last_activity_at: Time.current
    )
    
    user2 = users(:two)
    session2 = UserSession.create!(
      user: user2,
      session_id: SecureRandom.uuid,
      resource_type: 'Menu',
      resource_id: 2,
      status: 'active',
      last_activity_at: Time.current
    )
    
    active_users = PresenceService.get_active_users('Menu', 1)
    assert_includes active_users, @user
    assert_not_includes active_users, user2
  end
  
  test "user_online? should return true for active users" do
    UserSession.create!(
      user: @user,
      session_id: @session_id,
      status: 'active',
      last_activity_at: Time.current
    )
    
    assert PresenceService.user_online?(@user)
  end
  
  test "user_online? should return false for offline users" do
    assert_not PresenceService.user_online?(@user)
  end
  
  test "get_presence_status should return correct status" do
    UserSession.create!(
      user: @user,
      session_id: @session_id,
      status: 'idle',
      last_activity_at: Time.current
    )
    
    assert_equal 'idle', PresenceService.get_presence_status(@user)
  end
  
  test "get_presence_status should return offline for no sessions" do
    assert_equal 'offline', PresenceService.get_presence_status(@user)
  end
  
  test "cleanup_stale_sessions should mark old sessions as offline" do
    stale_session = UserSession.create!(
      user: @user,
      session_id: @session_id,
      status: 'active',
      last_activity_at: 10.minutes.ago
    )
    
    count = PresenceService.cleanup_stale_sessions(@user)
    assert_equal 1, count
    assert_equal 'offline', stale_session.reload.status
  end
  
  test "get_presence_summary should return summary for resource" do
    UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      resource_type: 'Menu',
      resource_id: 1,
      status: 'active',
      last_activity_at: Time.current
    )
    
    summary = PresenceService.get_presence_summary('Menu', 1)
    assert_equal 1, summary[:total]
    assert_equal 1, summary[:active]
    assert_equal 0, summary[:idle]
    assert_equal 1, summary[:users].length
  end
end
