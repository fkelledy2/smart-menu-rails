require 'test_helper'

class CurrentTest < ActiveSupport::TestCase
  setup do
    Current.clear_all
    @user = users(:one)
  end

  teardown do
    Current.clear_all
  end

  test 'can set and get user' do
    Current.user = @user
    assert_equal @user, Current.user
  end

  test 'user_id returns user id' do
    Current.user = @user
    assert_equal @user.id, Current.user_id
  end

  test 'user_id returns nil when no user' do
    Current.user = nil
    assert_nil Current.user_id
  end

  test 'user_email returns user email' do
    Current.user = @user
    assert_equal @user.email, Current.user_email
  end

  test 'user_email returns nil when no user' do
    Current.user = nil
    assert_nil Current.user_email
  end

  test 'authenticated? returns true when user present' do
    Current.user = @user
    assert Current.authenticated?
  end

  test 'authenticated? returns false when no user' do
    Current.user = nil
    assert_not Current.authenticated?
  end

  test 'set_user sets the user' do
    Current.set_user(@user)
    assert_equal @user, Current.user
  end

  test 'can set and get request_id' do
    Current.request_id = 'test-request-id'
    assert_equal 'test-request-id', Current.request_id
  end

  test 'can set and get user_agent' do
    Current.user_agent = 'Mozilla/5.0'
    assert_equal 'Mozilla/5.0', Current.user_agent
  end

  test 'can set and get ip_address' do
    Current.ip_address = '127.0.0.1'
    assert_equal '127.0.0.1', Current.ip_address
  end

  test 'can set and get session_id' do
    Current.session_id = 'session-123'
    assert_equal 'session-123', Current.session_id
  end

  test 'clear_all resets all attributes' do
    Current.user = @user
    Current.request_id = 'test-id'
    Current.user_agent = 'Mozilla'
    
    Current.clear_all
    
    assert_nil Current.user
    assert_nil Current.request_id
    assert_nil Current.user_agent
  end

  test 'attributes are thread-safe' do
    Current.user = @user
    
    thread = Thread.new do
      assert_nil Current.user
      Current.user = users(:two)
      assert_equal users(:two), Current.user
    end
    
    thread.join
    assert_equal @user, Current.user
  end

  test 'set_request_context sets request attributes' do
    request = OpenStruct.new(
      request_id: 'req-123',
      user_agent: 'Test Agent',
      remote_ip: '192.168.1.1',
      session: OpenStruct.new(id: 'session-456')
    )
    
    Current.set_request_context(request)
    
    assert_equal 'req-123', Current.request_id
    assert_equal 'Test Agent', Current.user_agent
    assert_equal '192.168.1.1', Current.ip_address
    assert_equal 'session-456', Current.session_id
  end

  test 'set_request_context handles nil session' do
    request = OpenStruct.new(
      request_id: 'req-123',
      user_agent: 'Test Agent',
      remote_ip: '192.168.1.1',
      session: nil
    )
    
    assert_nothing_raised do
      Current.set_request_context(request)
    end
  end
end
