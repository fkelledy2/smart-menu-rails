# frozen_string_literal: true

require 'test_helper'

class AnalyticsServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @service = AnalyticsService.instance
    
    # Enable analytics tracking in tests
    ENV['FORCE_ANALYTICS'] = 'true'
    
    # Mock the Analytics client
    @mock_client = Minitest::Mock.new
    @service.instance_variable_set(:@client, @mock_client)
  end

  def teardown
    ENV.delete('FORCE_ANALYTICS')
  end

  test "should track user events" do
    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == 'test_event' &&
      args[:properties].is_a?(Hash) &&
      args[:context].is_a?(Hash)
    end

    @service.track_user_event(@user, 'test_event', { test: 'data' })
    
    @mock_client.verify
  end

  test "should track anonymous events" do
    anonymous_id = 'test-anonymous-id'
    
    @mock_client.expect :track, nil, [
      {
        anonymous_id: anonymous_id,
        event: 'test_event',
        properties: Hash
      }
    ]

    @service.track_anonymous_event(anonymous_id, 'test_event', { test: 'data' })
    
    @mock_client.verify
  end

  test "should identify users" do
    @mock_client.expect :identify, nil, [
      {
        user_id: @user.id,
        traits: Hash,
        context: Hash
      }
    ]

    @service.identify_user(@user, { custom_trait: 'value' })
    
    @mock_client.verify
  end

  test "should track onboarding started" do
    @mock_client.expect :track, nil, [
      {
        user_id: @user.id,
        event: AnalyticsService::ONBOARDING_STARTED,
        properties: Hash,
        context: Hash
      }
    ]

    @service.track_onboarding_started(@user, 'homepage')
    
    @mock_client.verify
  end

  test "should track onboarding step completed" do
    @mock_client.expect :track, nil, [
      {
        user_id: @user.id,
        event: AnalyticsService::ONBOARDING_STEP_COMPLETED,
        properties: Hash,
        context: Hash
      }
    ]

    @service.track_onboarding_step_completed(@user, 1, { test_data: 'value' })
    
    @mock_client.verify
  end

  test "should handle errors gracefully" do
    @mock_client.expect :track, -> { raise StandardError.new('Test error') }, [Hash]

    # Should not raise an error
    assert_nothing_raised do
      @service.track_user_event(@user, 'test_event')
    end
  end

  test "should not track in test environment by default" do
    # In test environment, should_track? returns false unless FORCE_ANALYTICS is set
    refute @service.send(:should_track?)
  end

  test "should track when FORCE_ANALYTICS is set" do
    ENV['FORCE_ANALYTICS'] = 'true'
    
    assert @service.send(:should_track?)
    
    ENV.delete('FORCE_ANALYTICS')
  end

  test "should calculate progress percentage correctly" do
    assert_equal 20, @service.send(:calculate_progress_percentage, 1)
    assert_equal 40, @service.send(:calculate_progress_percentage, 2)
    assert_equal 60, @service.send(:calculate_progress_percentage, 3)
    assert_equal 80, @service.send(:calculate_progress_percentage, 4)
    assert_equal 100, @service.send(:calculate_progress_percentage, 5)
  end

  test "should return correct step names" do
    assert_equal 'account_details', @service.send(:step_name_for, 1)
    assert_equal 'restaurant_details', @service.send(:step_name_for, 2)
    assert_equal 'plan_selection', @service.send(:step_name_for, 3)
    assert_equal 'menu_creation', @service.send(:step_name_for, 4)
    assert_equal 'completion', @service.send(:step_name_for, 5)
    assert_equal 'unknown', @service.send(:step_name_for, 99)
  end
end
