require 'test_helper'

class CacheWarmingServiceTest < ActiveSupport::TestCase
  def setup
    @service = CacheWarmingService.instance
    @user = users(:one)
    @restaurant = restaurants(:one)
  end

  def teardown
    # Clean up any test data if needed
  end

  # Singleton tests
  test "should be a singleton" do
    service1 = CacheWarmingService.instance
    service2 = CacheWarmingService.instance
    assert_same service1, service2
  end

  test "should delegate class methods to instance" do
    assert_respond_to CacheWarmingService, :warm_all
    assert_respond_to CacheWarmingService, :warm_metrics
    assert_respond_to CacheWarmingService, :warm_analytics
    assert_respond_to CacheWarmingService, :warm_orders
  end

  # Main cache warming tests
  test "should warm all cache types successfully" do
    # Mock all the warming methods to avoid complex database queries
    @service.stub(:warm_metrics, true) do
      @service.stub(:warm_analytics, true) do
        @service.stub(:warm_orders, true) do
          @service.stub(:warm_user_data, true) do
            # Capture log output
            log_output = capture_logs do
              result = @service.warm_all
              assert_equal true, result
            end
            
            assert_includes log_output, "[CacheWarming] Starting comprehensive cache warming"
            assert_includes log_output, "[CacheWarming] Completed cache warming"
          end
        end
      end
    end
  end

  test "should handle errors gracefully in warm_all" do
    # Mock one method to raise an error
    @service.stub(:warm_metrics, -> { raise StandardError.new("Test error") }) do
      log_output = capture_logs do
        result = @service.warm_all
        assert_equal false, result
      end
      
      assert_includes log_output, "[CacheWarming] Failed to warm caches: Test error"
    end
  end

  test "should log execution time for cache warming" do
    # Mock all warming methods
    @service.stub(:warm_metrics, true) do
      @service.stub(:warm_analytics, true) do
        @service.stub(:warm_orders, true) do
          @service.stub(:warm_user_data, true) do
            log_output = capture_logs do
              @service.warm_all
            end
            
            # Should log execution time
            assert_match(/Completed cache warming in \d+\.\d+s/, log_output)
          end
        end
      end
    end
  end

  # Metrics warming tests
  test "should warm metrics caches with proper configuration" do
    # Mock QueryCacheService.warm_cache to capture the configs
    cache_configs_received = nil
    
    QueryCacheService.stub(:warm_cache, ->(configs) { cache_configs_received = configs }) do
      log_output = capture_logs do
        @service.warm_metrics
      end
      
      assert_includes log_output, "[CacheWarming] Warming metrics caches"
      assert_not_nil cache_configs_received
      assert_equal 3, cache_configs_received.length
      
      # Check cache config structure
      config = cache_configs_received.first
      assert_includes config.keys, :key
      assert_includes config.keys, :type
      assert_includes config.keys, :block
      assert_equal 'admin_metrics:admin_summary', config[:key]
      assert_equal :metrics_summary, config[:type]
    end
  end

  test "should warm analytics caches with proper configuration" do
    cache_configs_received = nil
    
    QueryCacheService.stub(:warm_cache, ->(configs) { cache_configs_received = configs }) do
      log_output = capture_logs do
        @service.warm_analytics
      end
      
      assert_includes log_output, "[CacheWarming] Warming analytics caches"
      assert_not_nil cache_configs_received
      assert_equal 2, cache_configs_received.length
      
      # Check analytics config structure
      config = cache_configs_received.first
      assert_equal 'dw_orders_mv:dw_orders_index:user_1', config[:key]
      assert_equal :order_analytics, config[:type]
    end
  end

  # Order warming tests
  test "should warm order caches for active restaurants" do
    cache_configs_received = nil
    
    # Mock active restaurants query
    mock_restaurants = [@restaurant]
    Restaurant.stub(:joins, Restaurant) do
      Restaurant.stub(:where, Restaurant) do
        Restaurant.stub(:distinct, Restaurant) do
          Restaurant.stub(:limit, mock_restaurants) do
            QueryCacheService.stub(:warm_cache, ->(configs) { cache_configs_received = configs }) do
              log_output = capture_logs do
                @service.warm_orders
              end
              
              assert_includes log_output, "[CacheWarming] Warming order caches"
              assert_not_nil cache_configs_received
              assert_equal 1, cache_configs_received.length
              
              config = cache_configs_received.first
              assert_equal "order_analytics:daily_stats:restaurant_#{@restaurant.id}", config[:key]
              assert_equal :daily_stats, config[:type]
            end
          end
        end
      end
    end
  end

  test "should handle empty active restaurants list" do
    cache_configs_received = nil
    
    # Mock empty restaurants query
    Restaurant.stub(:joins, Restaurant) do
      Restaurant.stub(:where, Restaurant) do
        Restaurant.stub(:distinct, Restaurant) do
          Restaurant.stub(:limit, []) do
            QueryCacheService.stub(:warm_cache, ->(configs) { cache_configs_received = configs }) do
              @service.warm_orders
              
              assert_not_nil cache_configs_received
              assert_equal 0, cache_configs_received.length
            end
          end
        end
      end
    end
  end

  # User data warming tests
  test "should warm user data caches for active users" do
    cache_configs_received = nil
    
    # Mock active users query
    mock_users = [@user]
    User.stub(:joins, User) do
      User.stub(:where, User) do
        User.stub(:distinct, User) do
          User.stub(:limit, mock_users) do
            QueryCacheService.stub(:warm_cache, ->(configs) { cache_configs_received = configs }) do
              log_output = capture_logs do
                @service.warm_user_data
              end
              
              assert_includes log_output, "[CacheWarming] Warming user data caches"
              assert_not_nil cache_configs_received
              assert_equal 2, cache_configs_received.length # 2 configs per user
              
              # Check user analytics config
              user_analytics_config = cache_configs_received.find { |c| c[:type] == :user_analytics }
              assert_not_nil user_analytics_config
              assert_equal "user_analytics:dashboard:user_#{@user.id}", user_analytics_config[:key]
              
              # Check restaurant analytics config
              restaurant_analytics_config = cache_configs_received.find { |c| c[:type] == :restaurant_analytics }
              assert_not_nil restaurant_analytics_config
              assert_equal "restaurant_analytics:summary:user_#{@user.id}", restaurant_analytics_config[:key]
            end
          end
        end
      end
    end
  end

  # Scheduling tests
  test "should schedule cache warming" do
    # Mock warm_all to avoid actual execution
    @service.stub(:warm_all, true) do
      log_output = capture_logs do
        @service.schedule_warming
      end
      
      assert_includes log_output, "[CacheWarming] Scheduling background cache warming"
    end
  end

  # Private method tests (testing through public interface)
  test "should generate admin metrics summary" do
    # Test through warm_metrics which calls warm_admin_metrics_summary
    QueryCacheService.stub(:warm_cache, ->(configs) {
      # Execute the block to test the private method
      summary = configs.find { |c| c[:type] == :metrics_summary }[:block].call
      
      assert_instance_of Hash, summary
      assert_includes summary.keys, :http_requests
      assert_includes summary.keys, :errors
      assert_includes summary.keys, :user_registrations
      assert_includes summary.keys, :restaurant_creations
      assert_includes summary.keys, :menu_imports
      assert_includes summary.keys, :avg_response_time
      assert_includes summary.keys, :error_rate
      
      # Check data structure
      assert_instance_of Hash, summary[:http_requests]
      assert_includes summary[:http_requests].keys, :total
      assert_includes summary[:http_requests].keys, :avg_per_hour
    }) do
      @service.warm_metrics
    end
  end

  test "should generate system metrics" do
    QueryCacheService.stub(:warm_cache, ->(configs) {
      system_metrics = configs.find { |c| c[:type] == :system_metrics }[:block].call
      
      assert_instance_of Hash, system_metrics
      assert_includes system_metrics.keys, :memory_usage
      assert_includes system_metrics.keys, :active_users
      assert_includes system_metrics.keys, :db_pool_size
      assert_includes system_metrics.keys, :db_pool_checked_out
      
      # Check memory usage structure
      assert_instance_of Hash, system_metrics[:memory_usage]
      assert_includes system_metrics[:memory_usage].keys, :current
      assert_includes system_metrics[:memory_usage].keys, :max
      assert_includes system_metrics[:memory_usage].keys, :unit
    }) do
      @service.warm_metrics
    end
  end

  test "should generate recent metrics" do
    QueryCacheService.stub(:warm_cache, ->(configs) {
      recent_metrics = configs.find { |c| c[:type] == :recent_metrics }[:block].call
      
      assert_instance_of Hash, recent_metrics
      assert_includes recent_metrics.keys, :recent_requests
      assert_includes recent_metrics.keys, :recent_errors
      assert_includes recent_metrics.keys, :recent_registrations
      assert_includes recent_metrics.keys, :recent_logins
      assert_includes recent_metrics.keys, :avg_recent_response_time
      
      # Check data types
      assert_instance_of Integer, recent_metrics[:recent_requests]
      assert_instance_of Integer, recent_metrics[:recent_errors]
      assert_instance_of Float, recent_metrics[:avg_recent_response_time]
    }) do
      @service.warm_metrics
    end
  end

  test "should generate order analytics data" do
    QueryCacheService.stub(:warm_cache, ->(configs) {
      order_analytics = configs.find { |c| c[:type] == :order_analytics }[:block].call
      
      assert_instance_of Array, order_analytics
      
      if order_analytics.any?
        order = order_analytics.first
        assert_includes order.keys, :id
        assert_includes order.keys, :restaurant_id
        assert_includes order.keys, :total
        assert_includes order.keys, :status
        assert_includes order.keys, :created_at
      end
    }) do
      @service.warm_analytics
    end
  end

  test "should generate user metrics data" do
    QueryCacheService.stub(:warm_cache, ->(configs) {
      user_metrics = configs.find { |c| c[:type] == :user_analytics }[:block].call
      
      assert_instance_of Array, user_metrics
      
      if user_metrics.any?
        metric = user_metrics.first
        assert_includes metric.keys, :id
        assert_includes metric.keys, :name
        assert_includes metric.keys, :value
        assert_includes metric.keys, :created_at
      end
    }) do
      @service.warm_analytics
    end
  end

  test "should generate restaurant order statistics" do
    # Mock Ordr queries to avoid schema issues
    mock_orders = Object.new
    mock_orders.define_singleton_method(:count) { 10 }
    mock_orders.define_singleton_method(:sum) { |field| 500.0 }
    mock_orders.define_singleton_method(:average) { |field| 50.0 }
    mock_orders.define_singleton_method(:where) { |conditions| mock_orders }
    
    Ordr.stub(:where, mock_orders) do
      QueryCacheService.stub(:warm_cache, ->(configs) {
        stats = configs.find { |c| c[:type] == :daily_stats }[:block].call
        
        assert_instance_of Hash, stats
        assert_includes stats.keys, :total_orders
        assert_includes stats.keys, :total_revenue
        assert_includes stats.keys, :avg_order_value
        assert_includes stats.keys, :completed_orders
        assert_includes stats.keys, :pending_orders
        
        assert_equal 10, stats[:total_orders]
        assert_equal 500.0, stats[:total_revenue]
        assert_equal 50.0, stats[:avg_order_value]
      }) do
        # Mock the restaurant query
        Restaurant.stub(:joins, Restaurant) do
          Restaurant.stub(:where, Restaurant) do
            Restaurant.stub(:distinct, Restaurant) do
              Restaurant.stub(:limit, [@restaurant]) do
                @service.warm_orders
              end
            end
          end
        end
      end
    end
  end

  test "should generate user dashboard data" do
    # Mock user and associations
    @user.stub(:restaurants, @user.restaurants) do
      @user.restaurants.stub(:count, 2) do
        @user.restaurants.stub(:joins, @user.restaurants) do
          @user.restaurants.stub(:sum, 1000.0) do
            @user.restaurants.stub(:where, @user.restaurants) do
              User.stub(:find_by, @user) do
                QueryCacheService.stub(:warm_cache, ->(configs) {
                  dashboard_data = configs.find { |c| c[:type] == :user_analytics }[:block].call
                  
                  assert_instance_of Hash, dashboard_data
                  assert_includes dashboard_data.keys, :restaurants_count
                  assert_includes dashboard_data.keys, :total_orders
                  assert_includes dashboard_data.keys, :total_revenue
                  assert_includes dashboard_data.keys, :active_menus
                  
                  assert_equal 2, dashboard_data[:restaurants_count]
                }) do
                  # Mock active users query
                  User.stub(:joins, User) do
                    User.stub(:where, User) do
                      User.stub(:distinct, User) do
                        User.stub(:limit, [@user]) do
                          @service.warm_user_data
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  test "should generate user restaurants data" do
    # Mock restaurant data
    mock_restaurant = OpenStruct.new(
      id: @restaurant.id,
      name: @restaurant.name,
      menus: [@restaurant.menus.first].compact,
      ordrs: [],
      status: 'active'
    )
    mock_restaurant.menus.define_singleton_method(:count) { 1 }
    mock_restaurant.ordrs.define_singleton_method(:count) { 0 }
    
    mock_restaurants = [mock_restaurant]
    mock_restaurants.define_singleton_method(:includes) { |*args| mock_restaurants }
    mock_restaurants.define_singleton_method(:limit) { |n| mock_restaurants }
    
    @user.stub(:restaurants, mock_restaurants) do
      User.stub(:find_by, @user) do
        QueryCacheService.stub(:warm_cache, ->(configs) {
          restaurants_data = configs.find { |c| c[:type] == :restaurant_analytics }[:block].call
          
          assert_instance_of Array, restaurants_data
          
          if restaurants_data.any?
            restaurant_data = restaurants_data.first
            assert_includes restaurant_data.keys, :id
            assert_includes restaurant_data.keys, :name
            assert_includes restaurant_data.keys, :menus_count
            assert_includes restaurant_data.keys, :orders_count
            assert_includes restaurant_data.keys, :status
            
            assert_equal @restaurant.id, restaurant_data[:id]
            assert_equal @restaurant.name, restaurant_data[:name]
          end
        }) do
          # Mock active users query
          User.stub(:joins, User) do
            User.stub(:where, User) do
              User.stub(:distinct, User) do
                User.stub(:limit, [@user]) do
                  @service.warm_user_data
                end
              end
            end
          end
        end
      end
    end
  end

  # Error handling tests
  test "should handle missing models gracefully in order analytics" do
    QueryCacheService.stub(:warm_cache, ->(configs) {
      # Test when DwOrdersMv is not defined - the method returns sample data instead
      order_analytics = configs.find { |c| c[:type] == :order_analytics }[:block].call
      
      # The method returns sample data even when model is not defined
      assert_instance_of Array, order_analytics
      assert_equal 3, order_analytics.length # Sample data has 3 items
    }) do
      @service.warm_analytics
    end
  end

  test "should handle missing models gracefully in user metrics" do
    QueryCacheService.stub(:warm_cache, ->(configs) {
      # Test when Metric model is not defined - the method returns sample data instead
      user_metrics = configs.find { |c| c[:type] == :user_analytics }[:block].call
      
      # The method returns sample data even when model is not defined
      assert_instance_of Array, user_metrics
      assert_equal 3, user_metrics.length # Sample data has 3 items
    }) do
      @service.warm_analytics
    end
  end

  test "should handle missing user in dashboard warming" do
    User.stub(:find_by, nil) do
      QueryCacheService.stub(:warm_cache, ->(configs) {
        dashboard_data = configs.find { |c| c[:type] == :user_analytics }[:block].call
        
        # Should return empty hash when user is not found
        assert_equal({}, dashboard_data)
      }) do
        # Mock active users query
        User.stub(:joins, User) do
          User.stub(:where, User) do
            User.stub(:distinct, User) do
              User.stub(:limit, [@user]) do
                @service.warm_user_data
              end
            end
          end
        end
      end
    end
  end

  test "should handle missing user in restaurants warming" do
    User.stub(:find_by, nil) do
      QueryCacheService.stub(:warm_cache, ->(configs) {
        restaurants_data = configs.find { |c| c[:type] == :restaurant_analytics }[:block].call
        
        # Should return empty array when user is not found
        assert_equal [], restaurants_data
      }) do
        # Mock active users query
        User.stub(:joins, User) do
          User.stub(:where, User) do
            User.stub(:distinct, User) do
              User.stub(:limit, [@user]) do
                @service.warm_user_data
              end
            end
          end
        end
      end
    end
  end

  # Integration tests
  test "should work with class method delegation" do
    # Mock all warming methods
    @service.stub(:warm_metrics, true) do
      @service.stub(:warm_analytics, true) do
        @service.stub(:warm_orders, true) do
          @service.stub(:warm_user_data, true) do
            # Test class method delegation
            result = CacheWarmingService.warm_all
            assert_equal true, result
          end
        end
      end
    end
  end

  test "should handle database errors gracefully" do
    # Mock a database error in one of the warming methods
    Restaurant.stub(:joins, -> (*args) { raise ActiveRecord::ConnectionNotEstablished.new("Database error") }) do
      # Should raise the error since the service doesn't catch database errors in warm_orders
      assert_raises(ActiveRecord::ConnectionNotEstablished) do
        @service.warm_orders
      end
    end
  end

  test "should handle QueryCacheService errors gracefully" do
    # Mock QueryCacheService to raise an error
    QueryCacheService.stub(:warm_cache, -> { raise StandardError.new("Cache service error") }) do
      # Should not raise error - let the calling method handle it
      assert_raises(StandardError) do
        @service.warm_metrics
      end
    end
  end

  private

  def capture_logs
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)
    
    yield
    
    log_output.string
  ensure
    Rails.logger = original_logger
  end
end
