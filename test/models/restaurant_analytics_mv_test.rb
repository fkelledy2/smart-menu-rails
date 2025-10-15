require 'test_helper'

class RestaurantAnalyticsMvTest < ActiveSupport::TestCase
  # Disable transactional tests for materialized views
  self.use_transactional_tests = false
  
  def setup
    @restaurant = restaurants(:one)
    
    # Create the materialized view if it doesn't exist in test context
    begin
      # Test if we can access the materialized view
      RestaurantAnalyticsMv.connection.execute('SELECT 1 FROM restaurant_analytics_mv LIMIT 1')
    rescue ActiveRecord::StatementInvalid => e
      # Create the materialized view for testing
      create_test_materialized_view
    end
  end
  
  private
  
  def create_test_materialized_view
    # Create a simplified version of the materialized view for testing
    sql = <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS restaurant_analytics_mv AS
      SELECT 
        r.id as restaurant_id,
        r.name as restaurant_name,
        r.currency as restaurant_currency,
        CURRENT_DATE as date,
        DATE_TRUNC('week', CURRENT_DATE) as week,
        DATE_TRUNC('month', CURRENT_DATE) as month,
        EXTRACT(HOUR FROM CURRENT_TIMESTAMP) as hour,
        EXTRACT(DOW FROM CURRENT_DATE) as day_of_week,
        0 as total_orders,
        0 as completed_orders,
        0 as cancelled_orders,
        0.0 as total_revenue,
        0.0 as avg_order_value,
        0 as unique_tables,
        0 as repeat_customers
      FROM restaurants r
      LIMIT 1;
    SQL
    
    RestaurantAnalyticsMv.connection.execute(sql)
  rescue ActiveRecord::StatementInvalid => e
    skip "Cannot create test materialized view: #{e.message}"
  end

  test "should be readonly" do
    # Test the readonly? method
    analytics = RestaurantAnalyticsMv.new
    assert analytics.readonly?
  end

  test "should have correct table name" do
    assert_equal 'restaurant_analytics_mv', RestaurantAnalyticsMv.table_name
  end

  test "should have no primary key" do
    assert_nil RestaurantAnalyticsMv.primary_key
  end

  test "should have scopes for common queries" do
    # Test that scopes exist and return ActiveRecord::Relation
    assert_respond_to RestaurantAnalyticsMv, :for_restaurant
    assert_respond_to RestaurantAnalyticsMv, :for_date_range
    assert_respond_to RestaurantAnalyticsMv, :for_month
    assert_respond_to RestaurantAnalyticsMv, :recent

    # Test scope chaining
    relation = RestaurantAnalyticsMv.for_restaurant(@restaurant.id)
    assert relation.is_a?(ActiveRecord::Relation)
    
    relation = RestaurantAnalyticsMv.for_date_range(1.week.ago, Time.current)
    assert relation.is_a?(ActiveRecord::Relation)
    
    relation = RestaurantAnalyticsMv.recent(30)
    assert relation.is_a?(ActiveRecord::Relation)
  end

  test "should calculate total orders for restaurant" do
    # Mock the query chain
    mock_relation = mock_analytics_relation(sum_result: 10)
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_relation) do
      total = RestaurantAnalyticsMv.total_orders_for_restaurant(@restaurant.id)
      assert_equal 10, total
    end
  end

  test "should calculate total orders for restaurant with date range" do
    date_range = 1.week.ago..Time.current
    mock_relation = mock_analytics_relation(sum_result: 15)
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:for_date_range, mock_relation) do
        total = RestaurantAnalyticsMv.total_orders_for_restaurant(@restaurant.id, date_range)
        assert_equal 15, total
      end
    end
  end

  test "should calculate total revenue for restaurant" do
    mock_relation = mock_analytics_relation(sum_result: 1000.0)
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_relation) do
      revenue = RestaurantAnalyticsMv.total_revenue_for_restaurant(@restaurant.id)
      assert_equal 1000.0, revenue
    end
  end

  test "should calculate total revenue for restaurant with date range" do
    date_range = 1.week.ago..Time.current
    mock_relation = mock_analytics_relation(sum_result: 1500.0)
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:for_date_range, mock_relation) do
        revenue = RestaurantAnalyticsMv.total_revenue_for_restaurant(@restaurant.id, date_range)
        assert_equal 1500.0, revenue
      end
    end
  end

  test "should get daily metrics" do
    mock_relation = mock_analytics_relation(
      sum_result: { 
        Date.current => { total_orders: 5, completed_orders: 4, total_revenue: 100.0 }
      }
    )
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:group, mock_relation) do
        metrics = RestaurantAnalyticsMv.daily_metrics(@restaurant.id)
        assert metrics.is_a?(Hash)
      end
    end
  end

  test "should get hourly distribution" do
    mock_relation = mock_analytics_relation(
      sum_result: { 12 => 5, 13 => 8, 18 => 10 }
    )
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:group, mock_relation) do
        distribution = RestaurantAnalyticsMv.hourly_distribution(@restaurant.id)
        assert distribution.is_a?(Hash)
        
        # Should be sorted by hour
        hours = distribution.keys
        assert_equal hours.sort, hours
      end
    end
  end

  test "should get peak hours" do
    hourly_data = { 12 => 5, 13 => 8, 18 => 10, 19 => 15, 20 => 12 }
    
    RestaurantAnalyticsMv.stub(:hourly_distribution, hourly_data) do
      peak_hours = RestaurantAnalyticsMv.peak_hours(@restaurant.id, nil, 3)
      
      assert_equal 3, peak_hours.size
      
      # Should be sorted by order count (descending)
      peak_hours_array = peak_hours.to_a
      assert peak_hours_array[0][1] >= peak_hours_array[1][1]
      assert peak_hours_array[1][1] >= peak_hours_array[2][1]
      
      # Top hour should be 19 (15 orders)
      assert_equal 19, peak_hours_array[0][0]
      assert_equal 15, peak_hours_array[0][1]
    end
  end

  test "should handle date range in all methods" do
    date_range = 1.week.ago..Time.current
    mock_relation = mock_analytics_relation(sum_result: 0)
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:for_date_range, mock_relation) do
        # All these methods should accept date_range parameter without error
        assert_nothing_raised do
          RestaurantAnalyticsMv.total_orders_for_restaurant(@restaurant.id, date_range)
          RestaurantAnalyticsMv.total_revenue_for_restaurant(@restaurant.id, date_range)
          RestaurantAnalyticsMv.daily_metrics(@restaurant.id, date_range)
          RestaurantAnalyticsMv.hourly_distribution(@restaurant.id, date_range)
          RestaurantAnalyticsMv.peak_hours(@restaurant.id, date_range)
        end
      end
    end
  end

  private

  def mock_analytics_relation(sum_result: 0)
    mock_relation = Object.new
    mock_relation.define_singleton_method(:for_restaurant) { |_| mock_relation }
    mock_relation.define_singleton_method(:for_date_range) { |_, _| mock_relation }
    mock_relation.define_singleton_method(:group) { |_| mock_relation }
    mock_relation.define_singleton_method(:sum) { |*_| sum_result }
    mock_relation
  end
end
