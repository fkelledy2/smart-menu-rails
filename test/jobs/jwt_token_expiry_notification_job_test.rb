# frozen_string_literal: true

require 'test_helper'

class JwtTokenExpiryNotificationJobTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def setup
    @admin_user = users(:super_admin)
    @restaurant = restaurants(:one)
  end

  test 'enqueues expiry warning emails for tokens expiring within 7 days' do
    # Create a token expiring in 3 days
    result = Jwt::TokenGenerator.call(
      admin_user: @admin_user,
      restaurant: @restaurant,
      name: 'Expiring Soon',
      scopes: ['menu:read'],
      expires_in: 3.days,
    )
    assert result.success?
    result.token

    assert_enqueued_emails 1 do
      JwtTokenExpiryNotificationJob.new.perform
    end
  end

  test 'does not enqueue emails for tokens not yet within 7 days of expiry' do
    result = Jwt::TokenGenerator.call(
      admin_user: @admin_user,
      restaurant: @restaurant,
      name: 'Not Expiring Soon',
      scopes: ['menu:read'],
      expires_in: 60.days,
    )
    assert result.success?

    # Only care about tokens for this test — isolate by checking count
    # The fixture tokens should not be in the 7-day window
    AdminJwtToken.where(name: 'Not Expiring Soon').first.tap do |t|
      assert_not AdminJwtToken.expiring_soon(7).include?(t)
    end
  end

  test 'purges usage logs older than 90 days' do
    # Manually age a log record
    log = jwt_token_usage_logs(:log_one)
    log.update_column(:created_at, 91.days.ago)

    assert_difference -> { JwtTokenUsageLog.count }, -1 do
      JwtTokenExpiryNotificationJob.new.perform
    end
  end

  test 'does not purge recent usage logs' do
    # Recent logs should not be touched
    log = jwt_token_usage_logs(:log_two)
    log.update_column(:created_at, 1.day.ago)

    assert_no_difference -> { JwtTokenUsageLog.count } do
      JwtTokenExpiryNotificationJob.new.perform
    end
  end
end
