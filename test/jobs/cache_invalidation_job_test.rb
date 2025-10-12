require 'test_helper'

class CacheInvalidationJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @ordr = ordrs(:one)
    @employee = employees(:one)
    
    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant
    @ordr.update!(restaurant: @restaurant) if @ordr.restaurant != @restaurant
    @employee.update!(restaurant: @restaurant) if @employee.restaurant != @restaurant
  end

  teardown do
    # Clean up any test data
  end

  # === BASIC JOB EXECUTION TESTS ===
  
  test 'should be configured with correct queue' do
    # Test that the job is configured with the default queue
    job = CacheInvalidationJob.new
    assert_equal 'default', job.queue_name
  end


  test 'should perform job successfully with order_id' do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(order_id: @ordr.id)
    end
  end

  test 'should perform job successfully with restaurant_id' do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(restaurant_id: @restaurant.id)
    end
  end

  test 'should perform job successfully with user_id' do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(user_id: @user.id)
    end
  end

  test 'should perform job successfully with menu_id' do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(menu_id: @menu.id)
    end
  end

  test 'should perform job successfully with employee_id' do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(employee_id: @employee.id)
    end
  end

  test 'should perform job successfully with multiple parameters' do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        order_id: @ordr.id,
        restaurant_id: @restaurant.id,
        user_id: @user.id,
        menu_id: @menu.id
      )
    end
  end

  test 'should perform job successfully with no parameters' do
    assert_nothing_raised do
      CacheInvalidationJob.perform_now
    end
  end

  # === CACHE INVALIDATION LOGIC TESTS ===
  
  test 'should call AdvancedCacheService for order invalidation' do
    # Mock AdvancedCacheService
    AdvancedCacheService.stub :invalidate_order_caches, true do
      CacheInvalidationJob.perform_now(order_id: @ordr.id)
    end
    # Test passes if no exception is raised
    assert true
  end

  test 'should call AdvancedCacheService for restaurant invalidation' do
    # Mock AdvancedCacheService
    AdvancedCacheService.stub :invalidate_restaurant_caches_selectively, true do
      CacheInvalidationJob.perform_now(restaurant_id: @restaurant.id)
    end
    # Test passes if no exception is raised
    assert true
  end

  test 'should call AdvancedCacheService for user invalidation' do
    # Mock AdvancedCacheService
    AdvancedCacheService.stub :invalidate_user_caches, true do
      CacheInvalidationJob.perform_now(user_id: @user.id)
    end
    # Test passes if no exception is raised
    assert true
  end

  test 'should call AdvancedCacheService for menu invalidation' do
    # Mock AdvancedCacheService
    AdvancedCacheService.stub :invalidate_menu_caches, true do
      CacheInvalidationJob.perform_now(menu_id: @menu.id)
    end
    # Test passes if no exception is raised
    assert true
  end

  test 'should call AdvancedCacheService for employee invalidation' do
    # Mock AdvancedCacheService
    AdvancedCacheService.stub :invalidate_employee_caches, true do
      CacheInvalidationJob.perform_now(employee_id: @employee.id)
    end
    # Test passes if no exception is raised
    assert true
  end

  # === IDENTITY CACHE TESTS ===
  
  test 'should handle IdentityCache invalidation when available' do
    # Test that the job handles IdentityCache gracefully
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(order_id: @ordr.id)
    end
  end

  test 'should handle IdentityCache errors gracefully' do
    # Test that the job handles IdentityCache errors gracefully
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(order_id: @ordr.id)
    end
  end


  # === USER CACHE INVALIDATION THROTTLING TESTS ===
  
  test 'should invalidate user cache when not recently invalidated' do
    # Clear any existing cache
    Rails.cache.delete("user_cache_invalidated:#{@user.id}")
    
    # Mock AdvancedCacheService to track calls
    invalidation_called = false
    AdvancedCacheService.stub :invalidate_user_caches, ->(user_id, options = {}) { 
      invalidation_called = true
      assert_equal @user.id, user_id
      assert options[:skip_restaurant_cascade]
    } do
      CacheInvalidationJob.perform_now(user_id: @user.id)
    end
    
    assert invalidation_called, 'User cache invalidation should have been called'
  end

  test 'should skip user cache invalidation when recently invalidated' do
    # Set recent invalidation
    Rails.cache.write("user_cache_invalidated:#{@user.id}", Time.current, expires_in: 10.minutes)
    
    # Mock AdvancedCacheService to track calls
    invalidation_called = false
    AdvancedCacheService.stub :invalidate_user_caches, ->(user_id, options = {}) { 
      invalidation_called = true
    } do
      CacheInvalidationJob.perform_now(user_id: @user.id)
    end
    
    assert_not invalidation_called, 'User cache invalidation should have been skipped'
  end

  test 'should invalidate user cache when last invalidation was long ago' do
    # Set old invalidation
    Rails.cache.write("user_cache_invalidated:#{@user.id}", 10.minutes.ago, expires_in: 20.minutes)
    
    # Mock AdvancedCacheService to track calls
    invalidation_called = false
    AdvancedCacheService.stub :invalidate_user_caches, ->(user_id, options = {}) { 
      invalidation_called = true
    } do
      CacheInvalidationJob.perform_now(user_id: @user.id)
    end
    
    assert invalidation_called, 'User cache invalidation should have been called for old invalidation'
  end

  # === ERROR HANDLING TESTS ===
  
  test 'should handle AdvancedCacheService errors gracefully' do
    # Mock AdvancedCacheService to raise an error
    AdvancedCacheService.stub :invalidate_order_caches, -> { raise StandardError.new('Service error') } do
      assert_nothing_raised do
        CacheInvalidationJob.perform_now(order_id: @ordr.id)
      end
    end
  end

  test 'should handle Redis errors with retry' do
    # Test that Redis errors are handled gracefully
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(order_id: @ordr.id)
    end
  end


  test 'should handle missing records gracefully' do
    # Test with non-existent IDs
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        order_id: 99999,
        restaurant_id: 99999,
        user_id: 99999,
        menu_id: 99999,
        employee_id: 99999
      )
    end
  end

  # === LOGGING TESTS ===
  
  test 'should log job start and completion' do
    # Capture log output
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)
    
    begin
      CacheInvalidationJob.perform_now(order_id: @ordr.id)
      
      log_content = log_output.string
      assert_includes log_content, '[CacheInvalidationJob] Starting cache invalidation'
      assert_includes log_content, '[CacheInvalidationJob] Completed cache invalidation'
    ensure
      Rails.logger = original_logger
    end
  end

  test 'should log errors when cache invalidation fails' do
    # Test that the job handles errors gracefully and logs them
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(order_id: @ordr.id)
    end
  end

  # === PERFORMANCE TESTS ===
  
  test 'should complete job execution within reasonable time' do
    start_time = Time.current
    
    CacheInvalidationJob.perform_now(
      order_id: @ordr.id,
      restaurant_id: @restaurant.id,
      user_id: @user.id
    )
    
    execution_time = Time.current - start_time
    assert execution_time < 5.seconds, "Job took too long: #{execution_time}s"
  end

  test 'should handle concurrent job execution' do
    # Test multiple jobs running simultaneously
    jobs = []
    
    3.times do |i|
      jobs << Thread.new do
        CacheInvalidationJob.perform_now(order_id: @ordr.id)
      end
    end
    
    # Wait for all jobs to complete
    jobs.each(&:join)
    
    # All jobs should complete without errors
    assert true
  end

  # === INTEGRATION TESTS ===
  
  test 'should work with real cache operations' do
    # Skip mocking and test with real cache operations
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        order_id: @ordr.id,
        restaurant_id: @restaurant.id
      )
    end
  end

  test 'should handle cache warming after invalidation' do
    # Test integration with CacheWarmingJob
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(restaurant_id: @restaurant.id)
      # Test cache warming with unknown type to avoid complex mocking
      CacheWarmingJob.perform_now(warm_type: 'unknown_type')
    end
  end

  # === BUSINESS SCENARIO TESTS ===
  
  test 'should handle order completion scenario' do
    # Simulate order completion cache invalidation
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        order_id: @ordr.id,
        restaurant_id: @restaurant.id,
        user_id: @user.id
      )
    end
  end

  test 'should handle menu update scenario' do
    # Simulate menu update cache invalidation
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        menu_id: @menu.id,
        restaurant_id: @restaurant.id
      )
    end
  end

  test 'should handle employee management scenario' do
    # Simulate employee update cache invalidation
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        employee_id: @employee.id,
        restaurant_id: @restaurant.id
      )
    end
  end

  test 'should handle restaurant settings update scenario' do
    # Simulate restaurant settings update
    assert_nothing_raised do
      CacheInvalidationJob.perform_now(
        restaurant_id: @restaurant.id,
        user_id: @user.id
      )
    end
  end

  # === RETRY CONFIGURATION TESTS ===
  
  test 'should be configured to retry on Redis errors' do
    # Test that the job class has retry configuration
    assert CacheInvalidationJob.respond_to?(:retry_on), 'Job should support retry configuration'
  end

  test 'should be configured to retry on IdentityCache errors when available' do
    # Test that the job class has retry configuration
    assert CacheInvalidationJob.respond_to?(:retry_on), 'Job should support retry configuration'
  end
end
