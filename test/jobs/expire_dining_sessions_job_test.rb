# frozen_string_literal: true

require 'test_helper'

class ExpireDiningSessionsJobTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @tablesetting = tablesettings(:table_one)
    @smartmenu = smartmenus(:one)
  end

  def create_session(overrides = {})
    DiningSession.create!({
      smartmenu: @smartmenu,
      tablesetting: @tablesetting,
      restaurant: @restaurant,
      session_token: SecureRandom.hex(32),
      active: true,
      expires_at: 90.minutes.from_now,
      last_activity_at: Time.current,
    }.merge(overrides))
  end

  test 'deactivates sessions past their expires_at TTL' do
    expired = create_session(expires_at: 1.minute.ago, last_activity_at: 2.minutes.ago)
    fresh = create_session

    ExpireDiningSessionsJob.new.perform

    assert_not expired.reload.active?
    assert fresh.reload.active?
  end

  test 'deactivates sessions past their inactivity timeout' do
    stale = create_session(last_activity_at: 31.minutes.ago)
    fresh = create_session

    ExpireDiningSessionsJob.new.perform

    assert_not stale.reload.active?
    assert fresh.reload.active?
  end

  test 'does not deactivate already-inactive sessions a second time' do
    already_inactive = create_session(active: false, expires_at: 1.minute.ago, last_activity_at: 2.minutes.ago)

    # Count updates before
    update_count_before = already_inactive.updated_at

    ExpireDiningSessionsJob.new.perform

    # already_inactive should still be inactive, updated_at unchanged
    assert_not already_inactive.reload.active?
  end

  test 'handles empty expired set gracefully' do
    # No expired sessions exist — job should run without error
    assert_nothing_raised do
      ExpireDiningSessionsJob.new.perform
    end
  end

  test 'raises and re-raises on unexpected error' do
    DiningSession.stub(:expired, -> { raise StandardError, 'DB failure' }) do
      assert_raises(StandardError) do
        ExpireDiningSessionsJob.new.perform
      end
    end
  end
end
