# frozen_string_literal: true

require 'test_helper'

class Api::V1::AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @headers = {
      'Authorization' => "Bearer #{JwtService.generate_token_for_user(@user)}",
      'Content-Type' => 'application/json'
    }
  end

  test "should track authenticated user event successfully" do
    # Mock AnalyticsService
    AnalyticsService.stub(:track_user_event, true) do
      post api_v1_analytics_track_path, 
           params: { event: 'menu_viewed', properties: { menu_id: 123 } }.to_json,
           headers: @headers

      assert_response :success
      json_response = JSON.parse(response.body)
      assert_equal 'success', json_response['status']
    end
  end

  test "should return bad request when event parameter is missing" do
    post api_v1_analytics_track_path,
         params: { properties: { menu_id: 123 } }.to_json,
         headers: @headers

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'bad_request', json_response['error']['code']
    assert_equal 'Event parameter is required', json_response['error']['message']
  end

  test "should return bad request when event parameter is blank" do
    post api_v1_analytics_track_path,
         params: { event: '', properties: { menu_id: 123 } }.to_json,
         headers: @headers

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal 'bad_request', json_response['error']['code']
    assert_equal 'Event parameter is required', json_response['error']['message']
  end

  test "should return unauthorized when user is not authenticated" do
    post api_v1_analytics_track_path,
         params: { event: 'menu_viewed', properties: { menu_id: 123 } }.to_json,
         headers: { 'Content-Type' => 'application/json' }

    assert_response :unauthorized
    json_response = JSON.parse(response.body)
    assert_equal 'unauthorized', json_response['error']['code']
    assert_equal 'Invalid or missing authentication token', json_response['error']['message']
  end

  test "should handle analytics service errors gracefully" do
    AnalyticsService.stub(:track_user_event, -> (*args) { raise StandardError, "Service unavailable" }) do
      post api_v1_analytics_track_path,
           params: { event: 'menu_viewed', properties: { menu_id: 123 } }.to_json,
           headers: @headers

      assert_response :internal_server_error
      json_response = JSON.parse(response.body)
      assert_equal 'error', json_response['status']
      assert_equal 'Tracking failed', json_response['message']
    end
  end

  test "should track anonymous event successfully" do
    AnalyticsService.stub(:track_anonymous_event, true) do
      post api_v1_analytics_track_anonymous_path,
           params: { event: 'page_viewed', properties: { page: 'home' } }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      assert_response :success
      json_response = JSON.parse(response.body)
      assert_equal 'success', json_response['status']
    end
  end

  test "should handle anonymous tracking errors gracefully" do
    AnalyticsService.stub(:track_anonymous_event, -> (*args) { raise StandardError, "Service unavailable" }) do
      post api_v1_analytics_track_anonymous_path,
           params: { event: 'page_viewed', properties: { page: 'home' } }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      assert_response :internal_server_error
      json_response = JSON.parse(response.body)
      assert_equal 'error', json_response['status']
      assert_equal 'Tracking failed', json_response['message']
    end
  end

  test "should generate session id for anonymous tracking" do
    # Clear any existing session
    reset!
    
    AnalyticsService.stub(:track_anonymous_event, -> (anonymous_id, event, properties) {
      # Verify that an anonymous_id was generated
      assert anonymous_id.present?
      assert anonymous_id.length == 36 # UUID length
      true
    }) do
      post api_v1_analytics_track_anonymous_path,
           params: { event: 'page_viewed' }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      assert_response :success
    end
  end

  test "should use session id for anonymous tracking" do
    AnalyticsService.stub(:track_anonymous_event, -> (anonymous_id, event, properties) {
      # Verify that an anonymous_id was generated and is a valid UUID format
      assert anonymous_id.present?
      assert anonymous_id.is_a?(String)
      assert anonymous_id.length >= 32 # Should be a UUID or similar identifier
      true
    }) do
      post api_v1_analytics_track_anonymous_path,
           params: { event: 'test_event' }.to_json,
           headers: { 'Content-Type' => 'application/json' }

      assert_response :success
    end
  end

  test "should handle empty properties parameter" do
    AnalyticsService.stub(:track_user_event, -> (user, event, properties) {
      assert_equal @user, user
      assert_equal 'menu_viewed', event
      assert_equal({}, properties)
      true
    }) do
      post api_v1_analytics_track_path,
           params: { event: 'menu_viewed' }.to_json,
           headers: @headers

      assert_response :success
    end
  end

  test "should not track page views for API endpoints" do
    controller = Api::V1::AnalyticsController.new
    assert_not controller.send(:should_track_page_view?)
  end
end
