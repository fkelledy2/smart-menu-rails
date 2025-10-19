require "test_helper"

class PushNotificationJobTest < ActiveJob::TestCase
  def setup
    @user = users(:one)
    @subscription = PushSubscription.create!(
      user: @user,
      endpoint: "https://fcm.googleapis.com/fcm/send/test",
      p256dh_key: "test_p256dh_key",
      auth_key: "test_auth_key",
      active: true
    )
    @payload = {
      title: "Test Notification",
      body: "Test message",
      data: { test: true }
    }
  end
  
  test "should perform job successfully" do
    # Skip if WebPush is not available
    skip "WebPush gem not available" unless defined?(WebPush)
    
    # Mock WebPush to avoid actual API calls
    WebPush.stub(:payload_send, true) do
      assert_nothing_raised do
        PushNotificationJob.new.perform(@subscription.id, @payload)
      end
    end
  end
  
  test "should skip if subscription not found" do
    assert_nothing_raised do
      PushNotificationJob.new.perform(999999, @payload)
    end
  end
  
  test "should skip if subscription is inactive" do
    @subscription.update!(active: false)
    
    assert_nothing_raised do
      PushNotificationJob.new.perform(@subscription.id, @payload)
    end
  end
  
  test "should deactivate subscription on InvalidSubscription error" do
    skip "WebPush gem not available" unless defined?(WebPush)
    
    WebPush.stub(:payload_send, -> (*) { raise WebPush::InvalidSubscription.new("Invalid") }) do
      PushNotificationJob.new.perform(@subscription.id, @payload)
    end
    
    assert_not @subscription.reload.active?
  end
  
  test "should deactivate subscription on ExpiredSubscription error" do
    skip "WebPush gem not available" unless defined?(WebPush)
    
    WebPush.stub(:payload_send, -> (*) { raise WebPush::ExpiredSubscription.new("Expired") }) do
      PushNotificationJob.new.perform(@subscription.id, @payload)
    end
    
    assert_not @subscription.reload.active?
  end
  
  test "should log error on other exceptions" do
    skip "WebPush gem not available" unless defined?(WebPush)
    
    # In test environment, errors are re-raised
    WebPush.stub(:payload_send, -> (*) { raise StandardError.new("Test error") }) do
      assert_raises(StandardError) do
        PushNotificationJob.new.perform(@subscription.id, @payload)
      end
    end
    
    # Subscription should still be active
    assert @subscription.reload.active?
  end
  
  test "should use VAPID configuration from environment" do
    skip "WebPush gem not available" unless defined?(WebPush)
    
    # Test that VAPID config is properly formatted
    job = PushNotificationJob.new
    vapid_config = job.send(:vapid_config)
    
    assert vapid_config.key?(:subject)
    assert vapid_config.key?(:public_key)
    assert vapid_config.key?(:private_key)
  end
  
  test "should handle missing WebPush gem gracefully" do
    # Temporarily hide WebPush constant
    webpush_const = Object.send(:remove_const, :WebPush) if defined?(WebPush)
    
    begin
      assert_nothing_raised do
        PushNotificationJob.new.perform(@subscription.id, @payload)
      end
    ensure
      # Restore WebPush constant if it existed
      Object.const_set(:WebPush, webpush_const) if webpush_const
    end
  end
end
