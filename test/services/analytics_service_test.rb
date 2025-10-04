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
    assert true, "Mock client expectations verified"
  end

  test "should track anonymous events" do
    anonymous_id = 'test-anonymous-id'
    
    @mock_client.expect :track, nil do |args|
      args[:anonymous_id] == anonymous_id &&
      args[:event] == 'test_event' &&
      args[:properties].is_a?(Hash)
    end

    @service.track_anonymous_event(anonymous_id, 'test_event', { test: 'data' })
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  test "should identify users" do
    @mock_client.expect :identify, nil do |args|
      args[:user_id] == @user.id &&
      args[:traits].is_a?(Hash) &&
      args[:context].is_a?(Hash)
    end

    @service.identify_user(@user)
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  test "should track onboarding started" do
    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == AnalyticsService::ONBOARDING_STARTED &&
      args[:properties].is_a?(Hash) &&
      args[:context].is_a?(Hash)
    end

    @service.track_onboarding_started(@user, 'homepage')
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  test "should track onboarding step completed" do
    @mock_client.expect :track, nil do |args|
      args[:event] == AnalyticsService::ONBOARDING_STEP_COMPLETED &&
      args[:properties].is_a?(Hash) &&
      args[:context].is_a?(Hash)
    end

    @service.track_onboarding_step_completed(@user, 'restaurant_created', { step: 1 })
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  test "should handle errors gracefully" do
    @mock_client.expect :track, -> { raise StandardError.new('Test error') }, [Hash]

    # Should not raise an error
    assert_nothing_raised do
      @service.track_user_event(@user, 'test_event')
    end
  end

  test "should not track in test environment by default" do
    # Temporarily remove FORCE_ANALYTICS to test default behavior
    ENV.delete('FORCE_ANALYTICS')
    
    # In test environment, should_track? returns false unless FORCE_ANALYTICS is set
    refute @service.send(:should_track?)
    
    # Restore FORCE_ANALYTICS for other tests
    ENV['FORCE_ANALYTICS'] = 'true'
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

  # Page tracking tests
  test "should track page views for users" do
    @mock_client.expect :page, nil do |args|
      args[:user_id] == @user.id &&
      args[:name] == 'dashboard' &&
      args[:properties].is_a?(Hash) &&
      args[:context].is_a?(Hash)
    end

    @service.track_page_view(@user, 'dashboard', { section: 'main' })
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  test "should track page views for anonymous users" do
    anonymous_id = 'test-anonymous-id'
    
    @mock_client.expect :page, nil do |args|
      args[:anonymous_id] == anonymous_id &&
      args[:name] == 'landing' &&
      args[:properties].is_a?(Hash)
    end

    @service.track_page_view(anonymous_id, 'landing', { campaign: 'google' })
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  # Onboarding tracking tests
  test "should track onboarding step failed" do
    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == AnalyticsService::ONBOARDING_STEP_FAILED &&
      args[:properties][:step] == 2 &&
      args[:properties][:step_name] == 'restaurant_details' &&
      args[:properties][:error_message] == 'Validation failed'
    end

    @service.track_onboarding_step_failed(@user, 2, 'Validation failed')
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  test "should track onboarding completed" do
    # Setup onboarding session with data
    onboarding = @user.onboarding_session
    onboarding.update!(
      restaurant_type: 'fast_casual',
      cuisine_type: 'italian',
      selected_plan_id: 1,
      menu_items: [{ name: 'Pizza', price: 12.99 }],
      status: :completed
    )

    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == AnalyticsService::ONBOARDING_COMPLETED &&
      args[:properties][:restaurant_type] == 'fast_casual' &&
      args[:properties][:cuisine_type] == 'italian' &&
      args[:properties][:menu_items_count] == 1 &&
      args[:properties][:selected_plan] == 1 &&
      args[:properties][:completion_rate] == 100
    end

    @service.track_onboarding_completed(@user)
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  # Restaurant tracking tests
  test "should track restaurant created" do
    restaurant = restaurants(:one)
    
    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == AnalyticsService::RESTAURANT_CREATED &&
      args[:properties][:restaurant_id] == restaurant.id &&
      args[:properties][:restaurant_name] == restaurant.name &&
      args[:properties][:via_onboarding] == true
    end

    @service.track_restaurant_created(@user, restaurant)
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  # Menu tracking tests
  test "should track menu created" do
    menu = menus(:one)
    
    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == AnalyticsService::MENU_CREATED &&
      args[:properties][:menu_id] == menu.id &&
      args[:properties][:menu_name] == menu.name &&
      args[:properties][:restaurant_id] == menu.restaurant_id &&
      args[:properties][:via_onboarding] == true
    end

    @service.track_menu_created(@user, menu)
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
  end

  # Feature usage tracking tests
  test "should track feature usage" do
    Thread.current[:analytics_restaurant_id] = 123
    
    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == AnalyticsService::FEATURE_USED &&
      args[:properties][:feature] == 'qr_code_generator' &&
      args[:properties][:restaurant_id] == 123
    end

    @service.track_feature_usage(@user, 'qr_code_generator', { format: 'png' })
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
    
    Thread.current[:analytics_restaurant_id] = nil
  end

  test "should track template usage" do
    Thread.current[:analytics_restaurant_id] = 456
    
    @mock_client.expect :track, nil do |args|
      args[:user_id] == @user.id &&
      args[:event] == AnalyticsService::TEMPLATE_USED &&
      args[:properties][:template_type] == 'menu_template' &&
      args[:properties][:restaurant_id] == 456
    end

    @service.track_template_usage(@user, 'menu_template', { style: 'modern' })
    
    @mock_client.verify
    assert true, "Mock client expectations verified"
    
    Thread.current[:analytics_restaurant_id] = nil
  end

  # User context tests
  test "should generate user context" do
    Thread.current[:analytics_user_agent] = 'Test Browser'
    Thread.current[:analytics_ip_address] = '192.168.1.1'
    
    context = @service.send(:user_context, @user)
    
    assert_equal I18n.locale, context[:locale]
    assert_equal Time.zone.name, context[:timezone]
    assert_equal 'Test Browser', context[:user_agent]
    assert_equal '192.168.1.1', context[:ip]
    
    Thread.current[:analytics_user_agent] = nil
    Thread.current[:analytics_ip_address] = nil
  end

  # Time calculation tests
  test "should calculate total onboarding time" do
    # Test with completed onboarding
    onboarding = @user.onboarding_session
    onboarding.update!(
      status: :completed,
      created_at: 1.hour.ago,
      updated_at: Time.current
    )
    
    total_time = @service.send(:calculate_total_onboarding_time, @user)
    assert_equal 60.0, total_time
  end

  test "should return nil for incomplete onboarding time" do
    onboarding = @user.onboarding_session
    onboarding.update!(status: :started)
    
    total_time = @service.send(:calculate_total_onboarding_time, @user)
    assert_nil total_time
  end

  test "should return nil for user without onboarding session" do
    user_without_onboarding = User.new
    
    total_time = @service.send(:calculate_total_onboarding_time, user_without_onboarding)
    assert_nil total_time
  end

  # Thread-local accessor tests
  test "should access thread-local values" do
    Thread.current[:analytics_user_agent] = 'Chrome'
    Thread.current[:analytics_ip_address] = '10.0.0.1'
    Thread.current[:analytics_path] = '/dashboard'
    Thread.current[:analytics_referrer] = 'https://google.com'
    Thread.current[:analytics_restaurant_id] = 789
    
    assert_equal 'Chrome', @service.send(:current_user_agent)
    assert_equal '10.0.0.1', @service.send(:current_ip_address)
    assert_equal '/dashboard', @service.send(:current_path)
    assert_equal 'https://google.com', @service.send(:current_referrer)
    assert_equal 789, @service.send(:current_restaurant_id)
    
    # Cleanup
    Thread.current[:analytics_user_agent] = nil
    Thread.current[:analytics_ip_address] = nil
    Thread.current[:analytics_path] = nil
    Thread.current[:analytics_referrer] = nil
    Thread.current[:analytics_restaurant_id] = nil
  end

  # Error handling tests
  test "should handle page tracking errors gracefully" do
    @mock_client.expect :page, -> { raise StandardError.new('Page tracking error') }, [Hash]

    assert_nothing_raised do
      @service.track_page_view(@user, 'error_page')
    end
  end

  test "should handle identify errors gracefully" do
    @mock_client.expect :identify, -> { raise StandardError.new('Identify error') }, [Hash]

    assert_nothing_raised do
      @service.identify_user(@user)
    end
  end

  test "should handle anonymous tracking errors gracefully" do
    @mock_client.expect :track, -> { raise StandardError.new('Anonymous tracking error') }, [Hash]

    assert_nothing_raised do
      @service.track_anonymous_event('test-id', 'test_event')
    end
  end

  # Singleton pattern tests
  test "should be a singleton" do
    instance1 = AnalyticsService.instance
    instance2 = AnalyticsService.instance
    
    assert_same instance1, instance2
  end

  test "should delegate missing methods to instance" do
    # Test that class methods delegate to instance
    assert_respond_to AnalyticsService, :track_user_event
    assert_respond_to AnalyticsService, :identify_user
    assert_respond_to AnalyticsService, :track_page_view
  end

  # Constants tests
  test "should have all required event constants" do
    # Onboarding events
    assert_equal 'onboarding_started', AnalyticsService::ONBOARDING_STARTED
    assert_equal 'onboarding_step_completed', AnalyticsService::ONBOARDING_STEP_COMPLETED
    assert_equal 'onboarding_step_failed', AnalyticsService::ONBOARDING_STEP_FAILED
    assert_equal 'onboarding_completed', AnalyticsService::ONBOARDING_COMPLETED
    assert_equal 'onboarding_abandoned', AnalyticsService::ONBOARDING_ABANDONED

    # User events
    assert_equal 'user_signed_up', AnalyticsService::USER_SIGNED_UP
    assert_equal 'user_signed_in', AnalyticsService::USER_SIGNED_IN
    assert_equal 'user_signed_out', AnalyticsService::USER_SIGNED_OUT
    assert_equal 'user_profile_updated', AnalyticsService::USER_PROFILE_UPDATED

    # Restaurant events
    assert_equal 'restaurant_created', AnalyticsService::RESTAURANT_CREATED
    assert_equal 'restaurant_updated', AnalyticsService::RESTAURANT_UPDATED
    assert_equal 'restaurant_viewed', AnalyticsService::RESTAURANT_VIEWED
    assert_equal 'restaurant_deleted', AnalyticsService::RESTAURANT_DELETED

    # Menu events
    assert_equal 'menu_created', AnalyticsService::MENU_CREATED
    assert_equal 'menu_updated', AnalyticsService::MENU_UPDATED
    assert_equal 'menu_viewed', AnalyticsService::MENU_VIEWED
    assert_equal 'menu_deleted', AnalyticsService::MENU_DELETED
    assert_equal 'menu_item_added', AnalyticsService::MENU_ITEM_ADDED
    assert_equal 'menu_item_updated', AnalyticsService::MENU_ITEM_UPDATED
    assert_equal 'menu_item_deleted', AnalyticsService::MENU_ITEM_DELETED

    # Order events
    assert_equal 'order_started', AnalyticsService::ORDER_STARTED
    assert_equal 'order_item_added', AnalyticsService::ORDER_ITEM_ADDED
    assert_equal 'order_item_removed', AnalyticsService::ORDER_ITEM_REMOVED
    assert_equal 'order_completed', AnalyticsService::ORDER_COMPLETED
    assert_equal 'order_cancelled', AnalyticsService::ORDER_CANCELLED

    # Business events
    assert_equal 'plan_selected', AnalyticsService::PLAN_SELECTED
    assert_equal 'plan_upgraded', AnalyticsService::PLAN_UPGRADED
    assert_equal 'plan_downgraded', AnalyticsService::PLAN_DOWNGRADED
    assert_equal 'subscription_cancelled', AnalyticsService::SUBSCRIPTION_CANCELLED

    # Feature usage events
    assert_equal 'feature_used', AnalyticsService::FEATURE_USED
    assert_equal 'qr_code_generated', AnalyticsService::QR_CODE_GENERATED
    assert_equal 'qr_code_scanned', AnalyticsService::QR_CODE_SCANNED
    assert_equal 'template_used', AnalyticsService::TEMPLATE_USED
  end
end
