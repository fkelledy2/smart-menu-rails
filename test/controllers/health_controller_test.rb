# frozen_string_literal: true

require 'test_helper'

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "should get basic health check" do
    get health_path
    assert_response :success
    
    # Check that response is not empty
    assert_not_empty response.body
    
    json_response = JSON.parse(response.body)
    assert_equal 'healthy', json_response['status']
    assert json_response['timestamp'].present?
    assert_equal Rails.env, json_response['environment']
  end
  
  test "should get redis health check when redis is available" do
    get health_redis_path
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'healthy', json_response['status']
    assert_equal 'redis', json_response['service']
    assert json_response['latency_ms'].is_a?(Numeric)
    assert json_response['timestamp'].present?
  end
  
  test "should handle redis health check failure gracefully" do
    # Mock Rails.cache to raise an error
    Rails.cache.stub(:write, -> (*args) { raise Redis::ConnectionError, "Connection refused" }) do
      get health_redis_path
      assert_response :service_unavailable
      
      json_response = JSON.parse(response.body)
      assert_equal 'unhealthy', json_response['status']
      assert_equal 'redis', json_response['service']
      assert json_response['error'].present?
      assert_equal 'Redis::ConnectionError', json_response['error_class']
    end
  end
  
  test "should get database health check" do
    get health_database_path
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'healthy', json_response['status']
    assert_equal 'database', json_response['service']
    assert json_response['latency_ms'].is_a?(Numeric)
    assert json_response['user_count'].is_a?(Numeric)
    assert json_response['adapter'].present?
  end
  
  test "should handle database health check failure gracefully" do
    # Mock ActiveRecord connection to raise an error
    ActiveRecord::Base.connection.stub(:execute, -> (*args) { raise ActiveRecord::ConnectionNotEstablished, "Database unavailable" }) do
      get health_database_path
      assert_response :service_unavailable
      
      json_response = JSON.parse(response.body)
      assert_equal 'unhealthy', json_response['status']
      assert_equal 'database', json_response['service']
      assert json_response['error'].present?
    end
  end
  
  test "should get full health check with all services healthy" do
    get health_full_path
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'healthy', json_response['status']
    assert json_response['services'].present?
    assert json_response['services']['redis'].present?
    assert json_response['services']['database'].present?
    assert json_response['services']['identity_cache'].present?
  end
  
  test "should return unhealthy status when redis fails in full check" do
    Rails.cache.stub(:write, -> (*args) { raise Redis::ConnectionError, "Connection refused" }) do
      get health_full_path
      assert_response :service_unavailable
      
      json_response = JSON.parse(response.body)
      assert_equal 'unhealthy', json_response['status']
      assert_equal 'unhealthy', json_response['services']['redis']['status']
    end
  end
  
  test "should return unhealthy status when database fails in full check" do
    ActiveRecord::Base.connection.stub(:execute, -> (*args) { raise ActiveRecord::ConnectionNotEstablished }) do
      get health_full_path
      assert_response :service_unavailable
      
      json_response = JSON.parse(response.body)
      assert_equal 'unhealthy', json_response['status']
      assert_equal 'unhealthy', json_response['services']['database']['status']
    end
  end
  
  test "should get cache stats" do
    get health_cache_stats_path
    assert_response :success
    
    json_response = JSON.parse(response.body)
    assert_equal 'healthy', json_response['status']
    assert json_response['cache_store'].present?
    assert json_response['timestamp'].present?
  end
  
  test "should handle cache stats error gracefully" do
    # Mock Rails.cache to raise an error when accessing redis
    Rails.cache.stub(:respond_to?, -> (method) { method == :redis ? true : Rails.cache.class.instance_method(:respond_to?).bind(Rails.cache).call(method) }) do
      Rails.cache.stub(:redis, -> { raise Redis::ConnectionError, "Connection refused" }) do
        get health_cache_stats_path
        assert_response :service_unavailable
        
        json_response = JSON.parse(response.body)
        assert_equal 'error', json_response['status']
        assert json_response['error'].present?
      end
    end
  end
  
  test "calculate_hit_rate should handle various inputs" do
    controller = HealthController.new
    
    # Test normal case
    assert_equal 75.0, controller.send(:calculate_hit_rate, 75, 25)
    
    # Test zero hits
    assert_equal 0.0, controller.send(:calculate_hit_rate, 0, 100)
    
    # Test zero total
    assert_equal 0.0, controller.send(:calculate_hit_rate, 0, 0)
    
    # Test nil values
    assert_equal 0, controller.send(:calculate_hit_rate, nil, nil)
    assert_equal 0, controller.send(:calculate_hit_rate, 100, nil)
  end
end
