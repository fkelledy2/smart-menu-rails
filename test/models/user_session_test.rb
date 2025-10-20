require "test_helper"

class UserSessionTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @session = UserSession.new(
      user: @user,
      session_id: SecureRandom.uuid,
      status: 'active',
      last_activity_at: Time.current
    )
  end
  
  # Validation tests
  test "should be valid with all required attributes" do
    assert @session.valid?
  end
  
  test "should require session_id" do
    @session.session_id = nil
    assert_not @session.valid?
    assert_includes @session.errors[:session_id], "can't be blank"
  end
  
  test "should require unique session_id" do
    @session.save!
    duplicate = UserSession.new(
      user: users(:two),
      session_id: @session.session_id,
      status: 'active'
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:session_id], "has already been taken"
  end
  
  test "should require status" do
    @session.status = nil
    assert_not @session.valid?
    assert_includes @session.errors[:status], "can't be blank"
  end
  
  test "should validate status inclusion" do
    @session.status = 'invalid'
    assert_not @session.valid?
    assert_includes @session.errors[:status], "is not included in the list"
  end
  
  test "should accept valid statuses" do
    %w[active idle offline].each do |status|
      @session.status = status
      assert @session.valid?, "#{status} should be valid"
    end
  end
  
  test "should belong to user" do
    assert_respond_to @session, :user
    assert_equal @user, @session.user
  end
  
  test "should have default status of active" do
    session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid
    )
    assert_equal 'active', session.status
  end
  
  # Scope tests
  test "active scope should return only active sessions" do
    active_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      status: 'active'
    )
    
    idle_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      status: 'idle'
    )
    
    active_sessions = UserSession.active
    assert_includes active_sessions, active_session
    assert_not_includes active_sessions, idle_session
  end
  
  test "idle scope should return only idle sessions" do
    idle_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      status: 'idle'
    )
    
    active_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      status: 'active'
    )
    
    idle_sessions = UserSession.idle
    assert_includes idle_sessions, idle_session
    assert_not_includes idle_sessions, active_session
  end
  
  test "for_resource scope should return sessions for specific resource" do
    session_with_resource = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      resource_type: 'Menu',
      resource_id: 1
    )
    
    session_without_resource = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid
    )
    
    resource_sessions = UserSession.for_resource('Menu', 1)
    assert_includes resource_sessions, session_with_resource
    assert_not_includes resource_sessions, session_without_resource
  end
  
  test "recent scope should return sessions with recent activity" do
    recent_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      last_activity_at: 1.minute.ago
    )
    
    old_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      last_activity_at: 10.minutes.ago
    )
    
    recent_sessions = UserSession.recent
    assert_includes recent_sessions, recent_session
    assert_not_includes recent_sessions, old_session
  end
  
  test "stale scope should return sessions with old activity" do
    stale_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      last_activity_at: 10.minutes.ago
    )
    
    recent_session = UserSession.create!(
      user: @user,
      session_id: SecureRandom.uuid,
      last_activity_at: 1.minute.ago
    )
    
    stale_sessions = UserSession.stale
    assert_includes stale_sessions, stale_session
    assert_not_includes stale_sessions, recent_session
  end
  
  # Method tests
  test "touch_activity! should update last_activity_at and set status to active" do
    @session.status = 'idle'
    @session.last_activity_at = 10.minutes.ago
    @session.save!
    
    @session.touch_activity!
    @session.reload
    
    assert_equal 'active', @session.status
    assert @session.last_activity_at > 1.minute.ago
  end
  
  test "mark_idle! should set status to idle" do
    @session.save!
    
    @session.mark_idle!
    assert_equal 'idle', @session.reload.status
  end
  
  test "mark_offline! should set status to offline" do
    @session.save!
    
    @session.mark_offline!
    assert_equal 'offline', @session.reload.status
  end
  
  test "stale? should return true for old sessions" do
    @session.last_activity_at = 10.minutes.ago
    assert @session.stale?
  end
  
  test "stale? should return false for recent sessions" do
    @session.last_activity_at = 1.minute.ago
    assert_not @session.stale?
  end
  
  test "stale? should return true for sessions without activity" do
    @session.last_activity_at = nil
    assert @session.stale?
  end
end
