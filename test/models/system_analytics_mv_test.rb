require 'test_helper'

class SystemAnalyticsMvTest < ActiveSupport::TestCase
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
