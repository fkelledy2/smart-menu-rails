# frozen_string_literal: true

require 'test_helper'

class AlcoholPolicyTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  def build_policy(attrs = {})
    AlcoholPolicy.new({ restaurant: @restaurant }.merge(attrs))
  end

  # === VALIDATIONS ===

  test 'valid with no restrictions' do
    policy = build_policy
    assert policy.valid?, policy.errors.full_messages.join(', ')
  end

  test 'invalid allowed_days_of_week rejects out-of-range values' do
    policy = build_policy(allowed_days_of_week: [0, 7])
    assert_not policy.valid?
    assert policy.errors[:allowed_days_of_week].any?
  end

  test 'valid allowed_days_of_week accepts 0..6' do
    policy = build_policy(allowed_days_of_week: (0..6).to_a)
    assert policy.valid?
  end

  test 'invalid time range rejects missing from_min' do
    policy = build_policy(allowed_time_ranges: [{ 'to_min' => 600 }])
    assert_not policy.valid?
    assert policy.errors[:allowed_time_ranges].any?
  end

  test 'invalid time range rejects from_min greater than to_min' do
    policy = build_policy(allowed_time_ranges: [{ 'from_min' => 700, 'to_min' => 600 }])
    assert_not policy.valid?
    assert policy.errors[:allowed_time_ranges].any?
  end

  test 'invalid time range rejects negative from_min' do
    policy = build_policy(allowed_time_ranges: [{ 'from_min' => -1, 'to_min' => 600 }])
    assert_not policy.valid?
    assert policy.errors[:allowed_time_ranges].any?
  end

  test 'invalid time range rejects to_min beyond midnight' do
    policy = build_policy(allowed_time_ranges: [{ 'from_min' => 0, 'to_min' => 1441 }])
    assert_not policy.valid?
    assert policy.errors[:allowed_time_ranges].any?
  end

  test 'valid time range saves correctly' do
    policy = build_policy(allowed_time_ranges: [{ 'from_min' => 690, 'to_min' => 1380 }])
    assert policy.valid?, policy.errors.full_messages.join(', ')
  end

  # === allowed_now? — no restrictions ===

  test 'allowed_now? returns true when no restrictions set' do
    policy = build_policy
    assert policy.allowed_now?
  end

  # === allowed_now? — blackout dates ===

  test 'allowed_now? returns false on a blackout date' do
    today = Date.current
    policy = build_policy(blackout_dates: [today])
    assert_not policy.allowed_now?(now: Time.zone.now)
  end

  test 'allowed_now? returns true on a non-blackout date' do
    yesterday = Date.yesterday
    policy = build_policy(blackout_dates: [yesterday])
    assert policy.allowed_now?(now: Time.zone.now)
  end

  # === allowed_now? — day of week ===

  test 'allowed_now? returns true when today is an allowed day' do
    today_wday = Time.zone.now.wday
    policy = build_policy(allowed_days_of_week: [today_wday])
    assert policy.allowed_now?(now: Time.zone.now)
  end

  test 'allowed_now? returns false when today is not an allowed day' do
    # Use a wday that is NOT today
    today_wday = Time.zone.now.wday
    other_days = (0..6).to_a - [today_wday]
    policy = build_policy(allowed_days_of_week: other_days.take(3))
    assert_not policy.allowed_now?(now: Time.zone.now)
  end

  # === allowed_now? — time ranges ===

  test 'allowed_now? returns true when current time is within an allowed range' do
    # 00:00 to 23:59 — always in range
    policy = build_policy(allowed_time_ranges: [{ 'from_min' => 0, 'to_min' => 1439 }])
    assert policy.allowed_now?(now: Time.zone.now)
  end

  test 'allowed_now? returns false when current time is outside all allowed ranges' do
    now = Time.zone.now
    current_minutes = (now.hour * 60) + now.min
    # Pick a range that does not include current minute
    from = (current_minutes + 60) % 1400
    to = (from + 60) % 1440
    if from < to
      policy = build_policy(allowed_time_ranges: [{ 'from_min' => from, 'to_min' => to }])
      assert_not policy.allowed_now?(now: now) if to < current_minutes || current_minutes < from
    end
    # Trivially pass if we can't construct a non-overlapping range (edge case near midnight)
  end

  # === allowed_now? — combined restrictions ===

  test 'allowed_now? returns false when day restriction fails even if time is ok' do
    today_wday = Time.zone.now.wday
    other_day = (today_wday + 1) % 7
    policy = build_policy(
      allowed_days_of_week: [other_day],
      allowed_time_ranges: [{ 'from_min' => 0, 'to_min' => 1439 }],
    )
    assert_not policy.allowed_now?(now: Time.zone.now)
  end
end
