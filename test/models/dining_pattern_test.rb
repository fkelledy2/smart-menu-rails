require 'test_helper'

class DiningPatternTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  def build_pattern(overrides = {})
    DiningPattern.new({
      restaurant: @restaurant,
      party_size: 4,
      day_of_week: 1,
      hour_of_day: 19,
      average_duration_minutes: 60.0,
      median_duration_minutes: 55.0,
      sample_count: 10,
      last_calculated_at: Time.current,
    }.merge(overrides))
  end

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test 'valid with all required attributes' do
    assert build_pattern.valid?
  end

  test 'invalid without party_size' do
    assert_not build_pattern(party_size: nil).valid?
  end

  test 'invalid with zero party_size' do
    assert_not build_pattern(party_size: 0).valid?
  end

  test 'invalid without day_of_week' do
    assert_not build_pattern(day_of_week: nil).valid?
  end

  test 'invalid with day_of_week below 0' do
    assert_not build_pattern(day_of_week: -1).valid?
  end

  test 'invalid with day_of_week above 6' do
    assert_not build_pattern(day_of_week: 7).valid?
  end

  test 'valid with day_of_week 0 (Sunday)' do
    assert build_pattern(day_of_week: 0).valid?
  end

  test 'valid with day_of_week 6 (Saturday)' do
    assert build_pattern(day_of_week: 6).valid?
  end

  test 'invalid without hour_of_day' do
    assert_not build_pattern(hour_of_day: nil).valid?
  end

  test 'invalid with hour_of_day below 0' do
    assert_not build_pattern(hour_of_day: -1).valid?
  end

  test 'invalid with hour_of_day above 23' do
    assert_not build_pattern(hour_of_day: 24).valid?
  end

  test 'valid with hour_of_day 0' do
    assert build_pattern(hour_of_day: 0).valid?
  end

  test 'valid with hour_of_day 23' do
    assert build_pattern(hour_of_day: 23).valid?
  end

  test 'invalid without average_duration_minutes' do
    assert_not build_pattern(average_duration_minutes: nil).valid?
  end

  test 'invalid with zero average_duration_minutes' do
    assert_not build_pattern(average_duration_minutes: 0).valid?
  end

  test 'invalid without median_duration_minutes' do
    assert_not build_pattern(median_duration_minutes: nil).valid?
  end

  test 'invalid without sample_count' do
    assert_not build_pattern(sample_count: nil).valid?
  end

  test 'invalid with negative sample_count' do
    assert_not build_pattern(sample_count: -1).valid?
  end

  test 'invalid without last_calculated_at' do
    assert_not build_pattern(last_calculated_at: nil).valid?
  end

  test 'uniqueness constraint: restaurant + party_size + day_of_week + hour_of_day' do
    dining_patterns(:party_of_2_monday_evening) # loads existing fixture
    duplicate = build_pattern(party_size: 2, day_of_week: 1, hour_of_day: 19)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:restaurant_id], 'already has a pattern for this party size, day, and hour'
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test 'for_party_size scope filters correctly' do
    results = DiningPattern.for_party_size(4)
    results.each { |dp| assert_equal 4, dp.party_size }
  end

  test 'for_day_and_hour scope filters correctly' do
    results = DiningPattern.for_day_and_hour(1, 19)
    results.each do |dp|
      assert_equal 1, dp.day_of_week
      assert_equal 19, dp.hour_of_day
    end
  end

  test 'sufficient_data scope requires at least 5 samples' do
    low = dining_patterns(:party_of_2_monday_evening_low_sample)
    assert_not DiningPattern.sufficient_data.include?(low)

    high = dining_patterns(:party_of_2_monday_evening)
    assert DiningPattern.sufficient_data.include?(high)
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test 'belongs to restaurant' do
    dp = dining_patterns(:party_of_2_monday_evening)
    assert_equal restaurants(:one), dp.restaurant
  end
end
