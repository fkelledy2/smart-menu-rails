require 'test_helper'

class ProfitMarginAnalyticsServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @service = ProfitMarginAnalyticsService.new(@restaurant)
  end

  test 'initializes with a restaurant' do
    assert_equal @restaurant, @service.instance_variable_get(:@restaurant)
  end

  test 'dashboard_stats returns a hash with expected keys' do
    result = @service.dashboard_stats
    assert_kind_of Hash, result
    assert_includes result.keys, :total_items
    assert_includes result.keys, :items_with_costs
    assert_includes result.keys, :average_margin_percentage
    assert_includes result.keys, :total_potential_profit
    assert_includes result.keys, :above_target_count
    assert_includes result.keys, :below_target_count
    assert_includes result.keys, :critical_count
    assert_includes result.keys, :no_target_count
    assert_includes result.keys, :top_performers
    assert_includes result.keys, :bottom_performers
    assert_includes result.keys, :category_breakdown
    assert_includes result.keys, :margin_trend
  end

  test 'dashboard_stats returns numeric values for counts' do
    result = @service.dashboard_stats
    assert_kind_of Integer, result[:total_items]
    assert_kind_of Integer, result[:items_with_costs]
    assert_kind_of Integer, result[:above_target_count]
    assert_kind_of Integer, result[:below_target_count]
    assert_kind_of Integer, result[:critical_count]
  end

  test 'dashboard_stats top_performers is an array' do
    result = @service.dashboard_stats
    assert_kind_of Array, result[:top_performers]
  end

  test 'dashboard_stats bottom_performers is an array' do
    result = @service.dashboard_stats
    assert_kind_of Array, result[:bottom_performers]
  end

  test 'order_profit_analytics returns hash with expected keys' do
    result = @service.order_profit_analytics
    assert_kind_of Hash, result
    assert_includes result.keys, :total_orders
    assert_includes result.keys, :total_revenue
    assert_includes result.keys, :total_profit
    assert_includes result.keys, :average_profit_per_order
    assert_includes result.keys, :profit_by_day_of_week
    assert_includes result.keys, :profit_by_hour
    assert_includes result.keys, :most_profitable_items
  end

  test 'order_profit_analytics total_orders is an integer' do
    result = @service.order_profit_analytics
    assert_kind_of Integer, result[:total_orders]
  end

  test 'order_profit_analytics accepts a custom date range' do
    result = @service.order_profit_analytics(date_range: 7.days.ago..Date.current)
    assert_kind_of Hash, result
    assert_kind_of Integer, result[:total_orders]
  end

  test 'dashboard_stats works with a date range' do
    result = @service.dashboard_stats(date_range: 7.days.ago..Date.current)
    assert_kind_of Hash, result
  end
end
