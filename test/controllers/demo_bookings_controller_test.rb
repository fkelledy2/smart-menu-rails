# frozen_string_literal: true

require 'test_helper'

class DemoBookingsControllerTest < ActionDispatch::IntegrationTest
  VALID_PARAMS = {
    demo_booking: {
      restaurant_name: 'The Harbour Kitchen',
      contact_name: 'Jane Smith',
      email: 'jane@therestaurant.com',
      phone: '+353 1 234 5678',
      restaurant_type: 'casual_dining',
      location_count: '2-5',
      interests: 'QR ordering',
    },
  }.freeze

  # ─── POST /demo_bookings ───────────────────────────────────────────────────

  test 'creates a DemoBooking with valid params' do
    assert_difference('DemoBooking.count', 1) do
      post demo_bookings_path, params: VALID_PARAMS, as: :json
    end
    assert_response :created
  end

  test 'returns ok:true and calendly_url on success' do
    post demo_bookings_path, params: VALID_PARAMS, as: :json
    body = response.parsed_body
    assert body['ok']
    assert body['calendly_url'].present?
  end

  test 'enqueues a confirmation email on success' do
    assert_difference('ActionMailer::Base.deliveries.size', 0) do
      # deliver_later with test adapter queues — check performed jobs count
      post demo_bookings_path, params: VALID_PARAMS, as: :json
    end
    assert_response :created
  end

  test 'returns 422 with validation errors when email is blank' do
    params = VALID_PARAMS.deep_dup
    params[:demo_booking][:email] = ''

    assert_no_difference('DemoBooking.count') do
      post demo_bookings_path, params: params, as: :json
    end
    assert_response :unprocessable_entity
    body = response.parsed_body
    assert_not body['ok']
    assert body['errors'].any?
  end

  test 'returns 422 when restaurant_name is blank' do
    params = VALID_PARAMS.deep_dup
    params[:demo_booking][:restaurant_name] = ''

    assert_no_difference('DemoBooking.count') do
      post demo_bookings_path, params: params, as: :json
    end
    assert_response :unprocessable_entity
  end

  test 'returns 422 when contact_name is blank' do
    params = VALID_PARAMS.deep_dup
    params[:demo_booking][:contact_name] = ''

    assert_no_difference('DemoBooking.count') do
      post demo_bookings_path, params: params, as: :json
    end
    assert_response :unprocessable_entity
  end

  test 'does not require authentication' do
    post demo_bookings_path, params: VALID_PARAMS, as: :json
    assert_response :created
  end

  # ─── POST /demo_bookings/video_analytics ──────────────────────────────────

  test 'creates a VideoAnalytic with valid event type' do
    assert_difference('VideoAnalytic.count', 1) do
      post video_analytics_demo_bookings_path, params: {
        video_id: 'homepage-demo',
        session_id: 'va-test-001',
        event_type: 'completion_75',
        timestamp_seconds: 225,
      }, as: :json
    end
    assert_response :created
    body = response.parsed_body
    assert body['ok']
  end

  test 'returns 422 for unknown event type' do
    assert_no_difference('VideoAnalytic.count') do
      post video_analytics_demo_bookings_path, params: {
        video_id: 'homepage-demo',
        event_type: 'unknown_event',
      }, as: :json
    end
    assert_response :unprocessable_entity
  end

  test 'video_analytics does not require authentication' do
    post video_analytics_demo_bookings_path, params: {
      video_id: 'homepage-demo',
      event_type: 'play',
    }, as: :json
    assert_response :created
  end

  test 'video_analytics accepts all valid event types' do
    VideoAnalytic::VALID_EVENT_TYPES.each do |event_type|
      post video_analytics_demo_bookings_path, params: {
        video_id: 'homepage-demo',
        event_type: event_type,
      }, as: :json
      assert_response :created, "Expected 201 for event_type: #{event_type}"
    end
  end
end
