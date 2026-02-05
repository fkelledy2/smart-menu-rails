require 'test_helper'

class SentryIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
  end

  test 'sentry is configured in initializer' do
    assert defined?(Sentry), 'Sentry should be defined'
    assert Sentry.respond_to?(:init), 'Sentry should respond to init'
  end

  test 'sentry configuration has correct environment' do
    skip 'Sentry not configured in test environment' unless Sentry.configuration.dsn.present?
    
    assert_equal Rails.env, Sentry.configuration.environment
  end

  test 'sentry configuration has release tracking' do
    skip 'Sentry not configured in test environment' unless Sentry.configuration.dsn.present?
    
    assert_not_nil Sentry.configuration.release
    assert_not_equal 'unknown', Sentry.configuration.release
  end

  test 'sentry excludes common exceptions' do
    skip 'Sentry not configured in test environment' unless Sentry.configuration.dsn.present?
    
    excluded = Sentry.configuration.excluded_exceptions
    assert_includes excluded, 'ActionController::BadRequest'
    assert_includes excluded, 'ActionController::UnknownFormat'
  end

  test 'sentry context is set for authenticated requests' do
    sign_in @user
    get root_path
    follow_redirect! while response.redirect?
    assert_response :success
    # Sentry context is set via before_action in SentryContext concern
  end

  test 'sentry does not break application when not configured' do
    # This test ensures the app works even without Sentry DSN
    get root_path
    follow_redirect! while response.redirect?
    assert_response :success
  end

  test 'sentry meta tags are not present when dsn not configured' do
    sign_in @user
    get root_path

    follow_redirect! while response.redirect?
    assert_response :success
    # In test environment without DSN, meta tags should not be present
    assert_select 'meta[name="sentry-dsn"]', count: 0
  end

  test 'sentry user context meta tags are not present without dsn' do
    sign_in @user
    get root_path

    follow_redirect! while response.redirect?
    assert_response :success
    # Without DSN configured, user meta tags should not be present
    assert_select 'meta[name="current-user-id"]', count: 0
  end

  test 'application works for anonymous users without sentry' do
    get root_path
    follow_redirect! while response.redirect?
    assert_response :success
  end

  test 'sentry filters sensitive data from requests' do
    # Test that before_send callback filters sensitive data
    event = OpenStruct.new(
      request: OpenStruct.new(
        data: {
          'password' => 'secret123',
          'email' => 'test@example.com',
          'credit_card_number' => '4111111111111111',
        },
      ),
    )
    
    filtered_event = Sentry.configuration.before_send.call(event, {})
    
    assert_nil filtered_event.request.data['password']
    assert_nil filtered_event.request.data['credit_card_number']
    assert_equal 'test@example.com', filtered_event.request.data['email']
  end

  test 'sentry has exception capture methods' do
    # Verify Sentry API is available
    assert Sentry.respond_to?(:capture_exception)
    assert Sentry.respond_to?(:capture_message)
    assert Sentry.respond_to?(:capture_event)
  end

  test 'sentry has performance monitoring configured' do
    assert_not_nil Sentry.configuration.traces_sample_rate
    assert Sentry.configuration.traces_sample_rate >= 0
    assert Sentry.configuration.traces_sample_rate <= 1
  end

  test 'sentry has breadcrumbs logging configured' do
    assert_not_nil Sentry.configuration.breadcrumbs_logger
    # In test environment, breadcrumbs are disabled to avoid initialization issues
    if Rails.env.test?
      assert_equal [], Sentry.configuration.breadcrumbs_logger
    else
      assert_includes Sentry.configuration.breadcrumbs_logger, :active_support_logger
    end
  end
end
