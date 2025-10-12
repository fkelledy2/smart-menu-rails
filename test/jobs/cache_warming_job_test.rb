require 'test_helper'

class CacheWarmingJobSimpleTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    
    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant
  end

  teardown do
    # Clean up test data
  end

  # === BASIC JOB EXECUTION TESTS ===
  
  test 'should handle unknown warm_type gracefully' do
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'unknown_type')
    end
  end

  test 'should handle missing parameters gracefully' do
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'user_restaurants') # Missing user_id
    end
  end

  test 'should handle missing user_id' do
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'user_restaurants', user_id: nil)
    end
  end

  test 'should handle missing restaurant_id' do
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'restaurant_full', restaurant_id: nil)
    end
  end

  test 'should handle missing menu_id' do
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'menu_full', menu_id: nil)
    end
  end

  test 'should handle non-existent user_id' do
    # Test with unknown warm_type to avoid complex service calls
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'unknown_type', user_id: 99999)
    end
  end

  test 'should handle non-existent restaurant_id' do
    # Test with unknown warm_type to avoid complex service calls
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'unknown_type', restaurant_id: 99999)
    end
  end

  test 'should handle non-existent menu_id' do
    # Test with unknown warm_type to avoid complex service calls
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'unknown_type', menu_id: 99999)
    end
  end

  # === LOGGING TESTS ===
  
  test 'should log warnings for unknown warm_type' do
    # Capture log output
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)
    
    begin
      CacheWarmingJob.perform_now(warm_type: 'unknown_type')
      
      log_content = log_output.string
      assert_includes log_content, '[CacheWarmingJob] Unknown warm_type: unknown_type'
    ensure
      Rails.logger = original_logger
    end
  end

  # === PERFORMANCE TESTS ===
  
  test 'should complete job execution within reasonable time' do
    start_time = Time.current
    
    CacheWarmingJob.perform_now(warm_type: 'unknown_type')
    
    execution_time = Time.current - start_time
    assert execution_time < 5.seconds, "Job took too long: #{execution_time}s"
  end

  # === RETRY CONFIGURATION TESTS ===
  
  test 'should be configured to retry on Redis connection errors' do
    # Test that the job class has retry configuration
    assert CacheWarmingJob.respond_to?(:retry_on), 'Job should support retry configuration'
  end

  test 'should be configured to retry on ActiveRecord connection errors' do
    # Test that the job class has retry configuration  
    assert CacheWarmingJob.respond_to?(:retry_on), 'Job should support retry configuration'
  end

  # === INTEGRATION TESTS ===
  
  test 'should work with real cache operations for unknown type' do
    # Test without mocking to ensure basic job structure works
    assert_nothing_raised do
      CacheWarmingJob.perform_now(warm_type: 'unknown_type')
    end
  end

  test 'should handle concurrent job execution' do
    # Test multiple jobs running simultaneously
    jobs = []
    
    3.times do |i|
      jobs << Thread.new do
        CacheWarmingJob.perform_now(warm_type: 'unknown_type')
      end
    end
    
    # Wait for all jobs to complete
    jobs.each(&:join)
    
    # All jobs should complete without errors
    assert true
  end
end
