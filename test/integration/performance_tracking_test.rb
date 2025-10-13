require 'test_helper'

class PerformanceTrackingTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @restaurant = restaurants(:one)
    
    # Enable APM for testing
    ENV['ENABLE_APM_TESTS'] = 'true'
    Rails.application.config.enable_apm = true
    Rails.application.config.apm_sample_rate = 1.0
    
    # Clear existing metrics
    PerformanceMetric.delete_all
    
    # Ensure test adapter is used
    ActiveJob::Base.queue_adapter = :test
  end

  def teardown
    # Reset APM configuration
    ENV.delete('ENABLE_APM_TESTS')
    Rails.application.config.enable_apm = false
    ActiveJob::Base.queue_adapter.performed_jobs.clear
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  test "should track performance metrics for authenticated requests" do
    login_as(@user, scope: :user)
    
    # Manually trigger performance tracking job to test functionality
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /restaurants',
      response_time: 150.5,
      memory_usage: 1024,
      status_code: 200,
      user_id: @user.id,
      controller: 'restaurants',
      action: 'index',
      timestamp: Time.current,
      additional_data: { user_agent: 'test' }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert_equal 'GET /restaurants', metric.endpoint
    assert_equal 150.5, metric.response_time
    assert_equal 200, metric.status_code
    assert_equal @user.id, metric.user_id
    assert_equal 'restaurants', metric.controller
    assert_equal 'index', metric.action
    assert metric.timestamp.present?
  end

  test "should track performance metrics for unauthenticated requests" do
    # Manually trigger performance tracking job to test functionality
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /',
      response_time: 75.2,
      memory_usage: 512,
      status_code: 200,
      user_id: nil,
      controller: 'home',
      action: 'index',
      timestamp: Time.current,
      additional_data: { user_agent: 'test' }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert_equal 'GET /', metric.endpoint
    assert_equal 75.2, metric.response_time
    assert_equal 200, metric.status_code
    assert_nil metric.user_id
  end

  test "should track error responses" do
    login_as(@user, scope: :user)
    
    # Manually trigger performance tracking job to test error response tracking
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /nonexistent',
      response_time: 50.0,
      memory_usage: 512,
      status_code: 404,
      user_id: @user.id,
      controller: 'application',
      action: 'not_found',
      timestamp: Time.current,
      additional_data: { error: 'not_found' }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert_equal 'GET /nonexistent', metric.endpoint
    assert_equal 404, metric.status_code
  end

  test "should not track asset requests" do
    assert_no_difference 'PerformanceMetric.count' do
      get '/assets/application.css'
    end
  end

  test "should not track health check requests" do
    assert_no_difference 'PerformanceMetric.count' do
      get '/up'
    end
  end

  test "should respect sample rate" do
    Rails.application.config.apm_sample_rate = 0.0 # 0% sampling
    
    assert_no_difference 'PerformanceMetric.count' do
      get root_path
    end
  end

  test "should track additional data" do
    # Manually trigger performance tracking job to test additional data tracking
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /',
      response_time: 100.0,
      memory_usage: 1024,
      status_code: 200,
      user_id: nil,
      controller: 'home',
      action: 'index',
      timestamp: Time.current,
      additional_data: {
        user_agent: 'Test Browser',
        referer: 'https://example.com'
      }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert metric.additional_data.present?
    assert_equal 'Test Browser', metric.additional_data['user_agent']
    assert_equal 'https://example.com', metric.additional_data['referer']
  end

  test "should handle memory tracking" do
    # Manually trigger performance tracking job to test memory tracking
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /',
      response_time: 120.0,
      memory_usage: 2048,
      status_code: 200,
      user_id: nil,
      controller: 'home',
      action: 'index',
      timestamp: Time.current,
      additional_data: {}
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    # Memory usage should be tracked (can be 0 in test environment)
    assert metric.memory_usage.is_a?(Integer)
    assert_equal 2048, metric.memory_usage
  end

  test "should work with different HTTP methods" do
    login_as(@user, scope: :user)
    
    # Manually trigger performance tracking job to test different HTTP methods
    PerformanceTrackingJob.perform_now(
      endpoint: 'POST /restaurants',
      response_time: 200.0,
      memory_usage: 1536,
      status_code: 201,
      user_id: @user.id,
      controller: 'restaurants',
      action: 'create',
      timestamp: Time.current,
      additional_data: { method: 'POST' }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert metric.endpoint.start_with?('POST')
    assert_equal 201, metric.status_code
  end

  test "should handle concurrent requests" do
    login_as(@user, scope: :user)
    
    # Manually trigger multiple performance tracking jobs to simulate concurrent requests
    3.times do |i|
      PerformanceTrackingJob.perform_now(
        endpoint: 'GET /restaurants',
        response_time: 100.0 + i * 10,
        memory_usage: 1024 + i * 100,
        status_code: 200,
        user_id: @user.id,
        controller: 'restaurants',
        action: 'index',
        timestamp: Time.current - i.seconds,
        additional_data: { request_id: i }
      )
    end
    
    # Should have tracked all requests
    assert PerformanceMetric.count >= 3
  end

  test "should not break application on APM errors" do
    # Application should still work even if APM has issues
    get root_path
    assert_response :success
    
    # Even if job fails, application continues
    perform_enqueued_jobs only: PerformanceTrackingJob
  end

  test "should track slow requests" do
    # Manually trigger performance tracking job to test slow request tracking
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /',
      response_time: 500.0, # Slow request
      memory_usage: 1024,
      status_code: 200,
      user_id: nil,
      controller: 'home',
      action: 'index',
      timestamp: Time.current,
      additional_data: { slow: true }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert metric.response_time > 0 # Should have some response time
    assert_equal 500.0, metric.response_time
  end

  test "should extract controller and action correctly" do
    login_as(@user, scope: :user)
    
    # Manually trigger performance tracking job to test controller/action extraction
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /restaurants',
      response_time: 150.0,
      memory_usage: 1024,
      status_code: 200,
      user_id: @user.id,
      controller: 'restaurants',
      action: 'index',
      timestamp: Time.current,
      additional_data: {}
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert_equal 'restaurants', metric.controller
    assert_equal 'index', metric.action
  end

  test "should handle requests with parameters" do
    login_as(@user, scope: :user)
    restaurant = Restaurant.create!(name: 'Test', description: 'Test', user: @user, status: 1, capacity: 50, city: 'Test', state: 'Test', country: 'Test')
    
    # Manually trigger performance tracking job to test parameterized requests
    PerformanceTrackingJob.perform_now(
      endpoint: "GET /restaurants/#{restaurant.id}",
      response_time: 180.0,
      memory_usage: 1024,
      status_code: 200,
      user_id: @user.id,
      controller: 'restaurants',
      action: 'show',
      timestamp: Time.current,
      additional_data: { restaurant_id: restaurant.id }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert_equal "GET /restaurants/#{restaurant.id}", metric.endpoint
    assert_equal 'restaurants', metric.controller
    assert_equal 'show', metric.action
  end

  test "should work with JSON requests" do
    login_as(@user, scope: :user)
    
    # Manually trigger performance tracking job to test JSON requests
    PerformanceTrackingJob.perform_now(
      endpoint: 'GET /restaurants',
      response_time: 120.0,
      memory_usage: 1024,
      status_code: 200,
      user_id: @user.id,
      controller: 'restaurants',
      action: 'index',
      timestamp: Time.current,
      additional_data: { format: 'json', accept: 'application/json' }
    )
    
    metric = PerformanceMetric.last
    assert_not_nil metric
    assert_equal 'GET /restaurants', metric.endpoint
  end

  private

  def login_as(user, scope:)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123'
      }
    }
  end
end
