require 'test_helper'

class AnalyticsReportingServiceV2Test < ActiveSupport::TestCase
  # Disable transactional tests for materialized views
  self.use_transactional_tests = false
  
  def setup
    @service = AnalyticsReportingServiceV2.instance
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user) if @restaurant.user != @user
    
    # Ensure materialized views are available for testing
    ensure_materialized_views_exist
  end
  
  private
  
  def ensure_materialized_views_exist
    # Create simplified materialized views if they don't exist
    views_to_create = [
      {
        name: 'restaurant_analytics_mv',
        sql: <<~SQL
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
      },
      {
        name: 'menu_performance_mv',
        sql: <<~SQL
          CREATE MATERIALIZED VIEW IF NOT EXISTS menu_performance_mv AS
          SELECT 
            r.id as restaurant_id,
            m.id as menu_id,
            m.name as menu_name,
            ms.id as menusection_id,
            ms.name as category_name,
            mi.id as menuitem_id,
            mi.name as item_name,
            mi.price as item_price,
            CURRENT_DATE as date,
            CURRENT_DATE as month,
            0 as times_ordered,
            0 as total_quantity,
            0.0 as total_revenue,
            0.0 as avg_item_revenue,
            1 as popularity_rank,
            0.0 as revenue_rank
          FROM restaurants r
          JOIN menus m ON m.restaurant_id = r.id
          JOIN menusections ms ON ms.menu_id = m.id
          JOIN menuitems mi ON mi.menusection_id = ms.id
          LIMIT 1;
        SQL
      },
      {
        name: 'system_analytics_mv',
        sql: <<~SQL
          CREATE MATERIALIZED VIEW IF NOT EXISTS system_analytics_mv AS
          SELECT 
            CURRENT_DATE as date,
            0 as total_restaurants,
            0 as total_orders,
            0.0 as total_revenue,
            0 as active_users
          LIMIT 1;
        SQL
      }
    ]
    
    views_to_create.each do |view|
      begin
        # Drop the existing view if it exists and recreate it with correct structure
        ActiveRecord::Base.connection.execute("DROP MATERIALIZED VIEW IF EXISTS #{view[:name]}")
        ActiveRecord::Base.connection.execute(view[:sql].gsub('IF NOT EXISTS', ''))
      rescue ActiveRecord::StatementInvalid => e
        # If we can't create the view, we'll rely on mocking in the tests
        Rails.logger.debug "Could not create test materialized view #{view[:name]}: #{e.message}"
      end
    end
  end

  test "should provide restaurant performance report using materialized views" do
    date_range = 7.days.ago..Time.current
    
    # Mock materialized view availability
    @service.stub(:materialized_views_healthy?, true) do
      report = @service.restaurant_performance_report(@restaurant.id, date_range)
      
      assert report.key?(:overview)
      assert report.key?(:orders)
      assert report.key?(:menu_performance)
      assert report.key?(:revenue)
      assert report.key?(:customer_insights)
      
      # Check overview structure
      overview = report[:overview]
      assert_equal @restaurant.name, overview[:name]
      assert overview.key?(:total_menus)
      assert overview.key?(:total_menu_items)
      
      # Check orders structure
      orders = report[:orders]
      assert orders.key?(:total_orders)
      assert orders.key?(:completed_orders)
      assert orders.key?(:cancelled_orders)
      assert orders.key?(:average_order_value)
      assert orders.key?(:orders_by_day)
      assert orders.key?(:orders_by_hour)
      assert orders.key?(:popular_items)
    end
  end

  test "should provide order analytics using materialized views" do
    date_range = 7.days.ago..Time.current
    
    # Mock the materialized view data
    mock_analytics_data = mock_restaurant_analytics_data
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_analytics_data) do
      mock_analytics_data.stub(:for_date_range, mock_analytics_data) do
        mock_analytics_data.stub(:sum, 0) do
          analytics = @service.order_analytics_mv(@restaurant.id, date_range)
          
          assert analytics.key?(:total_orders)
          assert analytics.key?(:completed_orders)
          assert analytics.key?(:cancelled_orders)
          assert analytics.key?(:average_order_value)
          assert analytics.key?(:orders_by_day)
          assert analytics.key?(:orders_by_hour)
          assert analytics.key?(:popular_items)
          
          # Values should be numeric
          assert analytics[:total_orders].is_a?(Numeric)
          assert analytics[:completed_orders].is_a?(Numeric)
          assert analytics[:cancelled_orders].is_a?(Numeric)
          assert analytics[:average_order_value].is_a?(Numeric)
        end
      end
    end
  end

  test "should provide revenue analytics using materialized views" do
    date_range = 30.days.ago..Time.current
    
    mock_analytics_data = mock_restaurant_analytics_data
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_analytics_data) do
      mock_analytics_data.stub(:for_date_range, mock_analytics_data) do
        mock_analytics_data.stub(:sum, 1000.0) do
          revenue = @service.revenue_analytics_mv(@restaurant.id, date_range)
          
          assert revenue.key?(:total_revenue)
          assert revenue.key?(:revenue_by_day)
          assert revenue.key?(:revenue_by_month)
          assert revenue.key?(:average_daily_revenue)
          assert revenue.key?(:revenue_growth)
          
          assert revenue[:total_revenue].is_a?(Numeric)
          assert revenue[:average_daily_revenue].is_a?(Numeric)
          assert revenue[:revenue_growth].is_a?(Numeric)
        end
      end
    end
  end

  test "should provide menu performance using materialized views" do
    date_range = 30.days.ago..Time.current
    
    # Mock MenuPerformanceMv methods
    MenuPerformanceMv.stub(:most_popular_items, []) do
      MenuPerformanceMv.stub(:least_popular_items, []) do
        MenuPerformanceMv.stub(:top_revenue_items, []) do
          MenuPerformanceMv.stub(:category_performance, {}) do
            performance = @service.menu_performance_mv(@restaurant.id, date_range)
            
            assert performance.key?(:most_ordered_items)
            assert performance.key?(:least_ordered_items)
            assert performance.key?(:menu_item_revenue)
            assert performance.key?(:category_performance)
            
            assert performance[:most_ordered_items].is_a?(Array)
            assert performance[:least_ordered_items].is_a?(Array)
            assert performance[:menu_item_revenue].is_a?(Array)
            assert performance[:category_performance].is_a?(Hash)
          end
        end
      end
    end
  end

  test "should provide customer insights using materialized views" do
    date_range = 30.days.ago..Time.current
    
    mock_analytics_data = mock_restaurant_analytics_data
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_analytics_data) do
      mock_analytics_data.stub(:for_date_range, mock_analytics_data) do
        mock_analytics_data.stub(:sum, 10) do
          RestaurantAnalyticsMv.stub(:peak_hours, {}) do
            insights = @service.customer_insights_mv(@restaurant.id, date_range)
            
            assert insights.key?(:unique_customers)
            assert insights.key?(:repeat_customers)
            assert insights.key?(:customer_frequency)
            assert insights.key?(:peak_hours)
            
            assert insights[:unique_customers].is_a?(Numeric)
            assert insights[:repeat_customers].is_a?(Numeric)
            assert insights[:customer_frequency].is_a?(Hash)
            assert insights[:peak_hours].is_a?(Hash)
          end
        end
      end
    end
  end

  test "should provide system analytics using materialized views" do
    date_range = 7.days.ago..Time.current
    
    SystemAnalyticsMv.stub(:total_metrics, mock_system_metrics) do
      analytics = @service.system_analytics_mv(date_range)
      
      assert analytics.key?(:total_restaurants)
      assert analytics.key?(:total_users)
      assert analytics.key?(:total_orders)
      assert analytics.key?(:total_revenue)
      
      assert analytics[:total_restaurants].is_a?(Numeric)
      assert analytics[:total_users].is_a?(Numeric)
      assert analytics[:total_orders].is_a?(Numeric)
      assert analytics[:total_revenue].is_a?(Numeric)
    end
  end

  test "should check materialized views health" do
    # Mock healthy views
    MaterializedViewService.stub(:health_check, { overall_status: :healthy }) do
      assert @service.materialized_views_healthy?
    end
    
    # Mock unhealthy views
    MaterializedViewService.stub(:health_check, { overall_status: :degraded }) do
      refute @service.materialized_views_healthy?
    end
  end

  test "should fall back to original service when views are unhealthy" do
    # Mock unhealthy views
    @service.stub(:materialized_views_healthy?, false) do
      # Mock the original service
      AnalyticsReportingService.stub(:restaurant_performance_report, mock_fallback_report) do
        report = @service.restaurant_performance_report_fallback(@restaurant.id)
        
        assert_equal mock_fallback_report, report
      end
    end
  end

  test "should export data using materialized views" do
    date_range = 30.days.ago..Time.current
    
    # Test CSV export
    mock_analytics_data = mock_restaurant_analytics_data_array
    
    RestaurantAnalyticsMv.stub(:for_restaurant, mock_analytics_data) do
      mock_analytics_data.stub(:for_date_range, mock_analytics_data) do
        mock_analytics_data.stub(:order, mock_analytics_data) do
          csv_data = @service.export_restaurant_data_mv(@restaurant.id, format: :csv, date_range: date_range)
          
          assert csv_data.is_a?(String)
          assert csv_data.include?('Date,Total Orders,Completed Orders')
        end
      end
    end
    
    # Test JSON export
    @service.stub(:restaurant_performance_report, mock_fallback_report) do
      json_data = @service.export_restaurant_data_mv(@restaurant.id, format: :json, date_range: date_range)
      
      assert json_data.is_a?(String)
      parsed_data = JSON.parse(json_data)
      assert parsed_data.is_a?(Hash)
    end
    
    # Test invalid format
    assert_raises ArgumentError do
      @service.export_restaurant_data_mv(@restaurant.id, format: :xml)
    end
  end

  private

  def mock_restaurant_analytics_data
    mock_data = Object.new
    mock_data.define_singleton_method(:for_restaurant) { |_| mock_data }
    mock_data.define_singleton_method(:for_date_range) { |_, _| mock_data }
    mock_data.define_singleton_method(:sum) { |_| 0 }
    mock_data.define_singleton_method(:group) { |_| mock_data }
    mock_data
  end

  def mock_restaurant_analytics_data_array
    mock_row = OpenStruct.new(
      date: Date.current,
      total_orders: 5,
      completed_orders: 4,
      cancelled_orders: 1,
      total_revenue: 100.0,
      unique_tables: 3
    )
    
    mock_data = [mock_row]
    mock_data.define_singleton_method(:for_restaurant) { |_| mock_data }
    mock_data.define_singleton_method(:for_date_range) { |_, _| mock_data }
    mock_data.define_singleton_method(:order) { |_| mock_data }
    mock_data
  end

  def mock_system_metrics
    {
      total_restaurants: 10,
      total_users: 50,
      total_orders: 100,
      total_revenue: 5000.0,
      active_restaurants: 8
    }
  end

  def mock_fallback_report
    {
      overview: { name: @restaurant.name },
      orders: { total_orders: 0 },
      menu_performance: {},
      revenue: { total_revenue: 0 },
      customer_insights: {}
    }
  end
end
