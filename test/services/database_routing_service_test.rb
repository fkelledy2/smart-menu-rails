require 'test_helper'

class DatabaseRoutingServiceTest < ActiveSupport::TestCase
  def setup
    # Clear any cached health checks
    DatabaseRoutingService.instance_variable_set(:@replica_health_cache, {})
  end

  def teardown
    # Clean up any instance variables
    DatabaseRoutingService.instance_variable_set(:@replica_health_cache, {})
  end

  # Basic functionality tests
  test "should be a class with class methods" do
    assert_respond_to DatabaseRoutingService, :with_analytics_connection
    assert_respond_to DatabaseRoutingService, :with_read_connection
    assert_respond_to DatabaseRoutingService, :with_primary_connection
    assert_respond_to DatabaseRoutingService, :replica_healthy?
    assert_respond_to DatabaseRoutingService, :replica_lag
    assert_respond_to DatabaseRoutingService, :connection_stats
    assert_respond_to DatabaseRoutingService, :route_query
  end

  # Analytics connection tests
  test "should execute analytics queries on replica with fallback" do
    executed_on_replica = false
    executed_on_primary = false
    
    # Mock ApplicationRecord.on_replica to succeed
    ApplicationRecord.stub(:on_replica, proc { |&block| executed_on_replica = true; block.call }) do
      result = DatabaseRoutingService.with_analytics_connection do
        "analytics_result"
      end
      
      assert_equal "analytics_result", result
      assert executed_on_replica
      assert_not executed_on_primary
    end
  end

  test "should fallback to primary when replica fails for analytics" do
    executed_on_replica = false
    executed_on_primary = false
    
    # Mock ApplicationRecord.on_replica to raise error
    ApplicationRecord.stub(:on_replica, proc { |&block| executed_on_replica = true; raise "Replica error" }) do
      ApplicationRecord.stub(:on_primary, proc { |&block| executed_on_primary = true; block.call }) do
        log_output = capture_logs do
          result = DatabaseRoutingService.with_analytics_connection do
            "fallback_result"
          end
          
          assert_equal "fallback_result", result
          assert executed_on_replica
          assert executed_on_primary
        end
        
        assert_includes log_output, "Analytics query failed on replica"
      end
    end
  end

  # Read connection tests
  test "should use replica for read queries when healthy" do
    executed_on_replica = false
    
    DatabaseRoutingService.stub(:replica_healthy?, true) do
      ApplicationRecord.stub(:on_replica, proc { |&block| executed_on_replica = true; block.call }) do
        result = DatabaseRoutingService.with_read_connection do
          "read_result"
        end
        
        assert_equal "read_result", result
        assert executed_on_replica
      end
    end
  end

  test "should use primary for read queries when replica unhealthy" do
    executed_on_primary = false
    
    DatabaseRoutingService.stub(:replica_healthy?, false) do
      ApplicationRecord.stub(:on_primary, proc { |&block| executed_on_primary = true; block.call }) do
        log_output = capture_logs do
          result = DatabaseRoutingService.with_read_connection do
            "primary_read_result"
          end
          
          assert_equal "primary_read_result", result
          assert executed_on_primary
        end
        
        assert_includes log_output, "Read replica unhealthy, using primary"
      end
    end
  end

  # Primary connection tests
  test "should always use primary for primary connection" do
    executed_on_primary = false
    
    ApplicationRecord.stub(:on_primary, proc { |&block| executed_on_primary = true; block.call }) do
      result = DatabaseRoutingService.with_primary_connection do
        "primary_result"
      end
      
      assert_equal "primary_result", result
      assert executed_on_primary
    end
  end

  # Replica health tests
  test "should return true for replica health in non-production environments" do
    Rails.env.stub(:production?, false) do
      assert DatabaseRoutingService.replica_healthy?
    end
  end

  test "should check actual replica health in production" do
    Rails.env.stub(:production?, true) do
      # Mock successful health check
      DatabaseRoutingService.stub(:check_replica_health, true) do
        assert DatabaseRoutingService.replica_healthy?
      end
    end
  end

  test "should cache replica health checks for 30 seconds" do
    Rails.env.stub(:production?, true) do
      check_count = 0
      
      DatabaseRoutingService.stub(:check_replica_health, proc { check_count += 1; true }) do
        # First call should check
        DatabaseRoutingService.replica_healthy?
        assert_equal 1, check_count
        
        # Second call within same 30-second window should use cache
        DatabaseRoutingService.replica_healthy?
        assert_equal 1, check_count
        
        # Simulate time passing (new cache key)
        Time.stub(:current, Time.current + 31.seconds) do
          DatabaseRoutingService.replica_healthy?
          assert_equal 2, check_count
        end
      end
    end
  end

  test "should handle replica health check errors gracefully" do
    Rails.env.stub(:production?, true) do
      DatabaseRoutingService.stub(:check_replica_health, proc { raise "Health check error" }) do
        log_output = capture_logs do
          result = DatabaseRoutingService.replica_healthy?
          assert_equal false, result
        end
        
        assert_includes log_output, "Failed to check replica health"
      end
    end
  end

  # Replica lag tests
  test "should calculate replica lag from PostgreSQL" do
    mock_result = [{ 'lag_seconds' => '2.5' }]
    mock_connection = Object.new
    mock_connection.define_singleton_method(:execute) { |sql| mock_result }
    
    ApplicationRecord.stub(:on_primary, proc { |&block| block.call }) do
      ApplicationRecord.stub(:connection, mock_connection) do
        lag = DatabaseRoutingService.replica_lag
        assert_equal 2.5, lag
      end
    end
  end

  test "should handle replica lag query errors" do
    ApplicationRecord.stub(:on_primary, proc { |&block| block.call }) do
      ApplicationRecord.stub(:connection, proc { raise "Connection error" }) do
        log_output = capture_logs do
          lag = DatabaseRoutingService.replica_lag
          assert_equal Float::INFINITY, lag
        end
        
        assert_includes log_output, "Failed to get replica lag"
      end
    end
  end

  test "should handle nil lag_seconds gracefully" do
    mock_result = [{ 'lag_seconds' => nil }]
    mock_connection = Object.new
    mock_connection.define_singleton_method(:execute) { |sql| mock_result }
    
    ApplicationRecord.stub(:on_primary, proc { |&block| block.call }) do
      ApplicationRecord.stub(:connection, mock_connection) do
        lag = DatabaseRoutingService.replica_lag
        assert_equal 0.0, lag
      end
    end
  end

  # Connection statistics tests
  test "should gather connection statistics for both primary and replica" do
    # Mock primary connection pool
    primary_stat = { size: 10, busy: 3 }
    primary_pool = Object.new
    primary_pool.define_singleton_method(:stat) { primary_stat }
    primary_pool.define_singleton_method(:respond_to?) { |method| method == :stat }
    
    # Mock replica connection pool
    replica_stat = { size: 5, busy: 1 }
    replica_pool = Object.new
    replica_pool.define_singleton_method(:stat) { replica_stat }
    replica_pool.define_singleton_method(:respond_to?) { |method| method == :stat }
    
    # Mock connection handler
    connection_handler = Object.new
    connection_handler.define_singleton_method(:retrieve_connection_pool) do |name|
      case name
      when 'primary' then primary_pool
      when 'replica' then replica_pool
      else nil
      end
    end
    
    ActiveRecord::Base.stub(:connection_handler, connection_handler) do
      DatabaseRoutingService.stub(:replica_lag, 1.5) do
        DatabaseRoutingService.stub(:replica_healthy?, true) do
          stats = DatabaseRoutingService.connection_stats
          
          # Check primary stats
          assert_equal 10, stats[:primary][:size]
          assert_equal 3, stats[:primary][:busy]
          assert_equal 7, stats[:primary][:available]
          assert_equal 30.0, stats[:primary][:utilization]
          
          # Check replica stats
          assert_equal 5, stats[:replica][:size]
          assert_equal 1, stats[:replica][:busy]
          assert_equal 4, stats[:replica][:available]
          assert_equal 20.0, stats[:replica][:utilization]
          
          # Check additional stats
          assert_equal 1.5, stats[:replica_lag]
          assert_equal true, stats[:replica_healthy]
        end
      end
    end
  end

  test "should handle connection pool errors gracefully" do
    # Mock connection handler that raises errors
    connection_handler = Object.new
    connection_handler.define_singleton_method(:retrieve_connection_pool) do |name|
      raise "Connection pool error for #{name}"
    end
    
    ActiveRecord::Base.stub(:connection_handler, connection_handler) do
      DatabaseRoutingService.stub(:replica_lag, 0.0) do
        DatabaseRoutingService.stub(:replica_healthy?, false) do
          log_output = capture_logs do
            stats = DatabaseRoutingService.connection_stats
            
            assert_includes stats[:primary].keys, :error
            assert_includes stats[:replica].keys, :error
            assert_equal 0.0, stats[:replica_lag]
            assert_equal false, stats[:replica_healthy]
          end
          
          assert_includes log_output, "Failed to get primary connection stats"
          assert_includes log_output, "Failed to get replica connection stats"
        end
      end
    end
  end

  test "should handle missing connection pools" do
    # Mock connection handler that returns nil
    connection_handler = Object.new
    connection_handler.define_singleton_method(:retrieve_connection_pool) { |name| nil }
    
    ActiveRecord::Base.stub(:connection_handler, connection_handler) do
      DatabaseRoutingService.stub(:replica_lag, 0.0) do
        DatabaseRoutingService.stub(:replica_healthy?, true) do
          stats = DatabaseRoutingService.connection_stats
          
          # Should not have primary or replica stats when pools are nil
          assert_nil stats[:primary]
          assert_nil stats[:replica]
          assert_equal 0.0, stats[:replica_lag]
          assert_equal true, stats[:replica_healthy]
        end
      end
    end
  end

  # Query routing tests
  test "should route analytics queries to analytics connection" do
    executed_analytics = false
    
    DatabaseRoutingService.stub(:with_analytics_connection, proc { |&block| executed_analytics = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :analytics) do
        "analytics_query_result"
      end
      
      assert_equal "analytics_query_result", result
      assert executed_analytics
    end
  end

  test "should route reporting queries to analytics connection" do
    executed_analytics = false
    
    DatabaseRoutingService.stub(:with_analytics_connection, proc { |&block| executed_analytics = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :reporting) do
        "reporting_query_result"
      end
      
      assert_equal "reporting_query_result", result
      assert executed_analytics
    end
  end

  test "should route read queries with strong consistency to primary" do
    executed_primary = false
    
    DatabaseRoutingService.stub(:with_primary_connection, proc { |&block| executed_primary = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :read, consistency: :strong) do
        "strong_read_result"
      end
      
      assert_equal "strong_read_result", result
      assert executed_primary
    end
  end

  test "should route read queries with immediate consistency to primary" do
    executed_primary = false
    
    DatabaseRoutingService.stub(:with_primary_connection, proc { |&block| executed_primary = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :read, consistency: :immediate) do
        "immediate_read_result"
      end
      
      assert_equal "immediate_read_result", result
      assert executed_primary
    end
  end

  test "should route read queries with eventual consistency to read connection" do
    executed_read = false
    
    DatabaseRoutingService.stub(:with_read_connection, proc { |&block| executed_read = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :read, consistency: :eventual) do
        "eventual_read_result"
      end
      
      assert_equal "eventual_read_result", result
      assert executed_read
    end
  end

  test "should route read queries with weak consistency to read connection" do
    executed_read = false
    
    DatabaseRoutingService.stub(:with_read_connection, proc { |&block| executed_read = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :read, consistency: :weak) do
        "weak_read_result"
      end
      
      assert_equal "weak_read_result", result
      assert executed_read
    end
  end

  test "should route read queries with unknown consistency to read connection" do
    executed_read = false
    
    DatabaseRoutingService.stub(:with_read_connection, proc { |&block| executed_read = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :read, consistency: :unknown) do
        "unknown_consistency_result"
      end
      
      assert_equal "unknown_consistency_result", result
      assert executed_read
    end
  end

  test "should route write queries to primary connection" do
    executed_primary = false
    
    DatabaseRoutingService.stub(:with_primary_connection, proc { |&block| executed_primary = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :write) do
        "write_result"
      end
      
      assert_equal "write_result", result
      assert executed_primary
    end
  end

  test "should route transaction queries to primary connection" do
    executed_primary = false
    
    DatabaseRoutingService.stub(:with_primary_connection, proc { |&block| executed_primary = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :transaction) do
        "transaction_result"
      end
      
      assert_equal "transaction_result", result
      assert executed_primary
    end
  end

  test "should route unknown query types to read connection" do
    executed_read = false
    
    DatabaseRoutingService.stub(:with_read_connection, proc { |&block| executed_read = true; block.call }) do
      result = DatabaseRoutingService.route_query(query_type: :unknown) do
        "unknown_query_result"
      end
      
      assert_equal "unknown_query_result", result
      assert executed_read
    end
  end

  test "should default to read connection when no query type specified" do
    executed_read = false
    
    DatabaseRoutingService.stub(:with_read_connection, proc { |&block| executed_read = true; block.call }) do
      result = DatabaseRoutingService.route_query do
        "default_query_result"
      end
      
      assert_equal "default_query_result", result
      assert executed_read
    end
  end

  # Private method tests (testing through public interface)
  test "should check replica health properly" do
    Rails.env.stub(:production?, true) do
      # Mock successful replica connection and acceptable lag
      ApplicationRecord.stub(:on_replica, proc { |&block| block.call }) do
        mock_connection = Object.new
        mock_connection.define_singleton_method(:execute) { |sql| true }
        
        ApplicationRecord.stub(:connection, mock_connection) do
          DatabaseRoutingService.stub(:replica_lag, 2.0) do # Under 5 second threshold
            assert DatabaseRoutingService.replica_healthy?
          end
        end
      end
    end
  end

  test "should fail health check when replica lag is too high" do
    Rails.env.stub(:production?, true) do
      # Mock successful replica connection but high lag
      ApplicationRecord.stub(:on_replica, proc { |&block| block.call }) do
        mock_connection = Object.new
        mock_connection.define_singleton_method(:execute) { |sql| true }
        
        ApplicationRecord.stub(:connection, mock_connection) do
          DatabaseRoutingService.stub(:replica_lag, 10.0) do # Over 5 second threshold
            log_output = capture_logs do
              result = DatabaseRoutingService.replica_healthy?
              assert_equal false, result
            end
            
            assert_includes log_output, "Replica lag too high: 10.0 seconds"
          end
        end
      end
    end
  end

  test "should fail health check when replica connection fails" do
    Rails.env.stub(:production?, true) do
      # Mock failing replica connection
      ApplicationRecord.stub(:on_replica, proc { |&block| raise "Connection failed" }) do
        log_output = capture_logs do
          result = DatabaseRoutingService.replica_healthy?
          assert_equal false, result
        end
        
        assert_includes log_output, "Replica health check failed"
      end
    end
  end

  # Integration tests
  test "should handle complete analytics workflow with fallback" do
    # First call fails on replica, second succeeds on primary
    replica_call_count = 0
    primary_call_count = 0
    
    ApplicationRecord.stub(:on_replica, proc { |&block| 
      replica_call_count += 1
      raise "Replica unavailable" 
    }) do
      ApplicationRecord.stub(:on_primary, proc { |&block| 
        primary_call_count += 1
        block.call 
      }) do
        log_output = capture_logs do
          result = DatabaseRoutingService.with_analytics_connection do
            "analytics_with_fallback"
          end
          
          assert_equal "analytics_with_fallback", result
          assert_equal 1, replica_call_count
          assert_equal 1, primary_call_count
        end
        
        assert_includes log_output, "Analytics query failed on replica"
      end
    end
  end

  test "should handle complete read workflow with health check" do
    health_check_count = 0
    
    DatabaseRoutingService.stub(:replica_healthy?, proc { 
      health_check_count += 1
      true 
    }) do
      ApplicationRecord.stub(:on_replica, proc { |&block| block.call }) do
        result = DatabaseRoutingService.with_read_connection do
          "healthy_read"
        end
        
        assert_equal "healthy_read", result
        assert_equal 1, health_check_count
      end
    end
  end

  test "should provide comprehensive connection monitoring" do
    # Mock all components for full stats
    primary_pool = Object.new
    primary_pool.define_singleton_method(:stat) { { size: 20, busy: 5 } }
    primary_pool.define_singleton_method(:respond_to?) { |method| method == :stat }
    
    replica_pool = Object.new
    replica_pool.define_singleton_method(:stat) { { size: 10, busy: 2 } }
    replica_pool.define_singleton_method(:respond_to?) { |method| method == :stat }
    
    connection_handler = Object.new
    connection_handler.define_singleton_method(:retrieve_connection_pool) do |name|
      case name
      when 'primary' then primary_pool
      when 'replica' then replica_pool
      end
    end
    
    ActiveRecord::Base.stub(:connection_handler, connection_handler) do
      DatabaseRoutingService.stub(:replica_lag, 0.8) do
        DatabaseRoutingService.stub(:replica_healthy?, true) do
          stats = DatabaseRoutingService.connection_stats
          
          # Verify comprehensive stats structure
          assert_instance_of Hash, stats
          assert_includes stats.keys, :primary
          assert_includes stats.keys, :replica
          assert_includes stats.keys, :replica_lag
          assert_includes stats.keys, :replica_healthy
          
          # Verify calculated utilization
          assert_equal 25.0, stats[:primary][:utilization]
          assert_equal 20.0, stats[:replica][:utilization]
        end
      end
    end
  end

  # Edge cases and error handling
  test "should handle zero busy connections" do
    pool = Object.new
    pool.define_singleton_method(:stat) { { size: 10, busy: 0 } }
    pool.define_singleton_method(:respond_to?) { |method| method == :stat }
    
    connection_handler = Object.new
    connection_handler.define_singleton_method(:retrieve_connection_pool) { |name| pool }
    
    ActiveRecord::Base.stub(:connection_handler, connection_handler) do
      DatabaseRoutingService.stub(:replica_lag, 0.0) do
        DatabaseRoutingService.stub(:replica_healthy?, true) do
          stats = DatabaseRoutingService.connection_stats
          
          assert_equal 0.0, stats[:primary][:utilization]
          assert_equal 10, stats[:primary][:available]
        end
      end
    end
  end

  test "should handle pool without stat method" do
    pool = Object.new
    pool.define_singleton_method(:respond_to?) { |method| false }
    
    connection_handler = Object.new
    connection_handler.define_singleton_method(:retrieve_connection_pool) { |name| pool }
    
    ActiveRecord::Base.stub(:connection_handler, connection_handler) do
      DatabaseRoutingService.stub(:replica_lag, 0.0) do
        DatabaseRoutingService.stub(:replica_healthy?, true) do
          stats = DatabaseRoutingService.connection_stats
          
          # Should not have detailed stats when pool doesn't respond to :stat
          assert_nil stats[:primary]
          assert_nil stats[:replica]
        end
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
