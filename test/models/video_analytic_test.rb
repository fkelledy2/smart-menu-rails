# frozen_string_literal: true

require 'test_helper'

class VideoAnalyticTest < ActiveSupport::TestCase
  test 'is valid with required attributes' do
    event = VideoAnalytic.new(video_id: 'homepage-demo', event_type: 'play')
    assert event.valid?
  end

  test 'is invalid without video_id' do
    event = VideoAnalytic.new(event_type: 'play')
    assert_not event.valid?
    assert event.errors[:video_id].any?
  end

  test 'is invalid without event_type' do
    event = VideoAnalytic.new(video_id: 'homepage-demo')
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  test 'is invalid with unknown event_type' do
    event = VideoAnalytic.new(video_id: 'homepage-demo', event_type: 'hacked')
    assert_not event.valid?
    assert event.errors[:event_type].any?
  end

  test 'accepts all valid event types' do
    VideoAnalytic::VALID_EVENT_TYPES.each do |type|
      event = VideoAnalytic.new(video_id: 'homepage-demo', event_type: type)
      assert event.valid?, "Expected #{type} to be valid"
    end
  end

  test '.completions_75 returns only completion_75 events' do
    VideoAnalytic.completions_75.each do |e|
      assert_equal 'completion_75', e.event_type
    end
  end

  test '.for_video filters by video_id' do
    VideoAnalytic.for_video('homepage-demo').each do |e|
      assert_equal 'homepage-demo', e.video_id
    end
  end

  test 'fixture play_event is valid' do
    assert video_analytics(:play_event).valid?
  end
end
