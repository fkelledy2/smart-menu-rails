require 'test_helper'

class MenuPerformanceMvTest < ActiveSupport::TestCase
  # Disable transactional tests for materialized views
  self.use_transactional_tests = false

  def setup
    @restaurant = restaurants(:one)
    @menu = menus(:one)

    # Create the materialized view if it doesn't exist in test context
    begin
      # Test if we can access the materialized view
      MenuPerformanceMv.connection.execute('SELECT 1 FROM menu_performance_mv LIMIT 1')
    rescue ActiveRecord::StatementInvalid
      # Create the materialized view for testing
      create_test_materialized_view
    end
  end

  private

  def create_test_materialized_view
    # Create a simplified version of the materialized view for testing
    sql = <<~SQL.squish
      CREATE MATERIALIZED VIEW IF NOT EXISTS menu_performance_mv AS
      SELECT#{' '}
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

    MenuPerformanceMv.connection.execute(sql)
  rescue ActiveRecord::StatementInvalid => e
    skip "Cannot create test materialized view: #{e.message}"
  end

  test 'should be readonly' do
    performance = MenuPerformanceMv.new
    assert performance.readonly?
  end

  test 'should have correct table name' do
    assert_equal 'menu_performance_mv', MenuPerformanceMv.table_name
  end

  test 'should have no primary key' do
    assert_nil MenuPerformanceMv.primary_key
  end

  test 'should have scopes for common queries' do
    # Test that scopes exist and return ActiveRecord::Relation
    assert_respond_to MenuPerformanceMv, :for_restaurant
    assert_respond_to MenuPerformanceMv, :for_menu
    assert_respond_to MenuPerformanceMv, :for_date_range
    assert_respond_to MenuPerformanceMv, :for_month
    assert_respond_to MenuPerformanceMv, :popular_items
    assert_respond_to MenuPerformanceMv, :top_revenue_items
    assert_respond_to MenuPerformanceMv, :recent

    # Test scope chaining
    relation = MenuPerformanceMv.for_restaurant(@restaurant.id)
    assert relation.is_a?(ActiveRecord::Relation)

    relation = MenuPerformanceMv.for_menu(@menu.id)
    assert relation.is_a?(ActiveRecord::Relation)

    relation = MenuPerformanceMv.popular_items(5)
    assert relation.is_a?(ActiveRecord::Relation)
  end

  test 'should get most popular items' do
    mock_relation = mock_performance_relation
    mock_grouped_data = {
      [1, 'Pizza Margherita'] => 15,
      [2, 'Pasta Carbonara'] => 12,
      [3, 'Caesar Salad'] => 8,
    }

    MenuPerformanceMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:popular_items, mock_relation) do
        mock_relation.stub(:group, mock_relation) do
          mock_relation.stub(:sum, mock_grouped_data) do
            popular = MenuPerformanceMv.most_popular_items(@restaurant.id, nil, 3)

            assert_equal 3, popular.size
            assert_equal 'Pizza Margherita', popular[0][:name]
            assert_equal 15, popular[0][:times_ordered]
            assert_equal 'Pasta Carbonara', popular[1][:name]
            assert_equal 12, popular[1][:times_ordered]
          end
        end
      end
    end
  end

  test 'should get least popular items' do
    mock_relation = mock_performance_relation
    mock_grouped_data = {
      [1, 'Unpopular Item'] => 1,
      [2, 'Another Unpopular'] => 2,
      [3, 'Rarely Ordered'] => 3,
    }

    MenuPerformanceMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:group, mock_relation) do
        mock_relation.stub(:sum, mock_grouped_data) do
          least_popular = MenuPerformanceMv.least_popular_items(@restaurant.id, nil, 3)

          assert_equal 3, least_popular.size
          assert_equal 'Unpopular Item', least_popular[0][:name]
          assert_equal 1, least_popular[0][:times_ordered]
        end
      end
    end
  end

  test 'should get top revenue items' do
    mock_relation = mock_performance_relation
    mock_grouped_data = {
      [1, 'Expensive Steak'] => 500.0,
      [2, 'Premium Wine'] => 300.0,
      [3, 'Lobster Dish'] => 250.0,
    }

    MenuPerformanceMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:top_revenue_items, mock_relation) do
        mock_relation.stub(:group, mock_relation) do
          mock_relation.stub(:sum, mock_grouped_data) do
            top_revenue = MenuPerformanceMv.top_revenue_items(@restaurant.id, nil, 3)

            assert_equal 3, top_revenue.size
            assert_equal 'Expensive Steak', top_revenue[0][:name]
            assert_equal 500.0, top_revenue[0][:revenue]
          end
        end
      end
    end
  end

  test 'should get category performance' do
    mock_relation = mock_performance_relation
    mock_grouped_data = {
      'Appetizers' => { total_revenue: 200.0, times_ordered: 25 },
      'Main Courses' => { total_revenue: 800.0, times_ordered: 40 },
      'Desserts' => { total_revenue: 150.0, times_ordered: 20 },
    }

    MenuPerformanceMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:group, mock_relation) do
        mock_relation.stub(:sum, mock_grouped_data) do
          performance = MenuPerformanceMv.category_performance(@restaurant.id)

          assert performance.is_a?(Hash)
          assert_equal mock_grouped_data, performance
        end
      end
    end
  end

  test 'should get menu summary' do
    mock_relation = mock_performance_relation

    MenuPerformanceMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:distinct, mock_relation) do
        mock_relation.stub(:count, 15) do # total_items
          mock_relation.stub(:sum, 100) do # total_orders
            mock_relation.stub(:average, 25.5) do # avg_item_revenue
              summary = MenuPerformanceMv.menu_summary(@restaurant.id)

              assert summary.key?(:total_items)
              assert summary.key?(:total_orders)
              assert summary.key?(:total_revenue)
              assert summary.key?(:avg_item_revenue)

              assert_equal 15, summary[:total_items]
              assert_equal 100, summary[:total_orders]
              assert_equal 25.5, summary[:avg_item_revenue]
            end
          end
        end
      end
    end
  end

  test 'should handle date range in all methods' do
    date_range = 1.week.ago..Time.current
    mock_relation = mock_performance_relation

    MenuPerformanceMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:for_date_range, mock_relation) do
        mock_relation.stub(:popular_items, mock_relation) do
          mock_relation.stub(:top_revenue_items, mock_relation) do
            mock_relation.stub(:group, mock_relation) do
              mock_relation.stub(:sum, {}) do
                mock_relation.stub(:distinct, mock_relation) do
                  mock_relation.stub(:count, 0) do
                    mock_relation.stub(:average, 0.0) do
                      # All these methods should accept date_range parameter without error
                      assert_nothing_raised do
                        MenuPerformanceMv.most_popular_items(@restaurant.id, date_range)
                        MenuPerformanceMv.least_popular_items(@restaurant.id, date_range)
                        MenuPerformanceMv.top_revenue_items(@restaurant.id, date_range)
                        MenuPerformanceMv.category_performance(@restaurant.id, date_range)
                        MenuPerformanceMv.menu_summary(@restaurant.id, date_range)
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

  test 'should handle empty results gracefully' do
    mock_relation = mock_performance_relation

    MenuPerformanceMv.stub(:for_restaurant, mock_relation) do
      mock_relation.stub(:popular_items, mock_relation) do
        mock_relation.stub(:group, mock_relation) do
          mock_relation.stub(:sum, {}) do
            popular = MenuPerformanceMv.most_popular_items(@restaurant.id)
            assert_equal [], popular

            least_popular = MenuPerformanceMv.least_popular_items(@restaurant.id)
            assert_equal [], least_popular

            top_revenue = MenuPerformanceMv.top_revenue_items(@restaurant.id)
            assert_equal [], top_revenue
          end
        end
      end
    end
  end

  def mock_performance_relation
    mock_relation = Object.new
    mock_relation.define_singleton_method(:for_restaurant) { |_| mock_relation }
    mock_relation.define_singleton_method(:for_menu) { |_| mock_relation }
    mock_relation.define_singleton_method(:for_date_range) { |_, _| mock_relation }
    mock_relation.define_singleton_method(:popular_items) { |_| mock_relation }
    mock_relation.define_singleton_method(:top_revenue_items) { |_| mock_relation }
    mock_relation.define_singleton_method(:group) { |_| mock_relation }
    mock_relation.define_singleton_method(:sum) { |*_| {} }
    mock_relation.define_singleton_method(:distinct) { mock_relation }
    mock_relation.define_singleton_method(:count) { |_| 0 }
    mock_relation.define_singleton_method(:average) { |_| 0.0 }
    mock_relation
  end
end
