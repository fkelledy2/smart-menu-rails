require 'test_helper'

class SystemAnalyticsMvTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    conn = ApplicationRecord.connection
    relkind = conn.select_value(<<~SQL.squish)
      SELECT c.relkind
      FROM pg_class c
      WHERE c.oid = to_regclass('system_analytics_mv')
    SQL

    if relkind == 'm'
      conn.execute('DROP MATERIALIZED VIEW IF EXISTS system_analytics_mv')
    elsif relkind == 'v'
      conn.execute('DROP VIEW IF EXISTS system_analytics_mv')
    end

    ApplicationRecord.connection.execute(<<~SQL.squish)
      CREATE VIEW system_analytics_mv AS
      SELECT
        CURRENT_DATE AS date,
        DATE_TRUNC('month', CURRENT_DATE)::date AS month,
        0::integer AS new_restaurants,
        0::integer AS new_users,
        0::integer AS new_menus,
        0::integer AS new_menuitems,
        0::integer AS total_orders,
        0::numeric AS total_revenue,
        0::integer AS active_restaurants
    SQL

    SystemAnalyticsMv.reset_column_information
  end

  teardown do
    conn = ApplicationRecord.connection
    relkind = conn.select_value(<<~SQL.squish)
      SELECT c.relkind
      FROM pg_class c
      WHERE c.oid = to_regclass('system_analytics_mv')
    SQL

    if relkind == 'm'
      conn.execute('DROP MATERIALIZED VIEW IF EXISTS system_analytics_mv')
    elsif relkind == 'v'
      conn.execute('DROP VIEW IF EXISTS system_analytics_mv')
    end
  end

  test 'uses correct table name' do
    assert_equal 'system_analytics_mv', SystemAnalyticsMv.table_name
  end

  test 'has no primary key' do
    assert_nil SystemAnalyticsMv.primary_key
  end

  test 'is readonly' do
    mv = SystemAnalyticsMv.new
    assert mv.readonly?
  end

  test 'cannot be saved' do
    mv = SystemAnalyticsMv.new
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      mv.save
    end
  end

  test 'has for_date_range scope' do
    assert_respond_to SystemAnalyticsMv, :for_date_range
  end

  test 'has for_month scope' do
    assert_respond_to SystemAnalyticsMv, :for_month
  end

  test 'has recent scope' do
    assert_respond_to SystemAnalyticsMv, :recent
  end

  test 'has current_month scope' do
    assert_respond_to SystemAnalyticsMv, :current_month
  end

  test 'has previous_month scope' do
    assert_respond_to SystemAnalyticsMv, :previous_month
  end

  test 'has total_metrics class method' do
    assert_respond_to SystemAnalyticsMv, :total_metrics
  end

  test 'has daily_growth class method' do
    assert_respond_to SystemAnalyticsMv, :daily_growth
  end

  test 'has monthly_growth class method' do
    assert_respond_to SystemAnalyticsMv, :monthly_growth
  end

  test 'has growth_rate class method' do
    assert_respond_to SystemAnalyticsMv, :growth_rate
  end

  test 'has active_restaurant_trend class method' do
    assert_respond_to SystemAnalyticsMv, :active_restaurant_trend
  end

  test 'has admin_summary class method' do
    assert_respond_to SystemAnalyticsMv, :admin_summary
  end

  test 'can query records' do
    assert_nothing_raised do
      SystemAnalyticsMv.all.to_a
    end
  end
end
