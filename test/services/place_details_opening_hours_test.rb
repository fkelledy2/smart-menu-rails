require 'test_helper'

class PlaceDetailsOpeningHoursTest < ActiveSupport::TestCase
  def setup
    @service = GooglePlaces::PlaceDetails.new(api_key: 'test_key')
  end

  test 'parse_opening_hours returns nil when nil input' do
    assert_nil @service.send(:parse_opening_hours, nil)
  end

  test 'parse_opening_hours returns nil when no periods' do
    assert_nil @service.send(:parse_opening_hours, { 'periods' => [] })
  end

  test 'parse_opening_hours parses standard periods' do
    periods = {
      'periods' => [
        { 'open' => { 'day' => 1, 'time' => '0900' }, 'close' => { 'day' => 1, 'time' => '2200' } },
        { 'open' => { 'day' => 2, 'time' => '1100' }, 'close' => { 'day' => 2, 'time' => '2300' } },
      ],
    }

    result = @service.send(:parse_opening_hours, periods)
    assert_equal 2, result.length

    monday = result[0]
    assert_equal 1, monday['day']
    assert_equal 9, monday['open_hour']
    assert_equal 0, monday['open_min']
    assert_equal 22, monday['close_hour']
    assert_equal 0, monday['close_min']

    tuesday = result[1]
    assert_equal 2, tuesday['day']
    assert_equal 11, tuesday['open_hour']
    assert_equal 0, tuesday['open_min']
    assert_equal 23, tuesday['close_hour']
    assert_equal 0, tuesday['close_min']
  end

  test 'parse_opening_hours handles 24/7 venue' do
    # Google signals 24/7 with a single period: open day=0, time=0000, no close
    periods = {
      'periods' => [
        { 'open' => { 'day' => 0, 'time' => '0000' } },
      ],
    }

    result = @service.send(:parse_opening_hours, periods)
    assert_equal 7, result.length
    result.each_with_index do |day_data, idx|
      assert_equal idx, day_data['day']
      assert_equal 0, day_data['open_hour']
      assert_equal 0, day_data['open_min']
      assert_equal 23, day_data['close_hour']
      assert_equal 59, day_data['close_min']
    end
  end

  test 'parse_opening_hours handles times with minutes' do
    periods = {
      'periods' => [
        { 'open' => { 'day' => 5, 'time' => '1130' }, 'close' => { 'day' => 5, 'time' => '2145' } },
      ],
    }

    result = @service.send(:parse_opening_hours, periods)
    assert_equal 1, result.length
    assert_equal 11, result[0]['open_hour']
    assert_equal 30, result[0]['open_min']
    assert_equal 21, result[0]['close_hour']
    assert_equal 45, result[0]['close_min']
  end

  test 'parse_opening_hours skips periods with missing open data' do
    periods = {
      'periods' => [
        { 'close' => { 'day' => 1, 'time' => '2200' } },
        { 'open' => { 'day' => 2, 'time' => '0900' }, 'close' => { 'day' => 2, 'time' => '1700' } },
      ],
    }

    result = @service.send(:parse_opening_hours, periods)
    assert_equal 1, result.length
    assert_equal 2, result[0]['day']
  end
end
