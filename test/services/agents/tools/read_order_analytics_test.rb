# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::ReadOrderAnalyticsTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'returns expected keys in result hash' do
    result = call_tool(period: 'this week')
    assert_includes result.keys, :total_orders
    assert_includes result.keys, :total_revenue_formatted
    assert_includes result.keys, :avg_ticket_formatted
    assert_includes result.keys, :top_items
    assert_includes result.keys, :period
  end

  test 'returns zero orders for empty date range' do
    result = call_tool(period: 'yesterday')
    assert result[:total_orders] >= 0
  end

  test 'defaults to last week when period is blank' do
    result = call_tool(period: nil)
    assert_equal 'last week', result[:period]
  end

  test 'defaults to last week for unrecognised period string' do
    result = call_tool(period: 'three fiscal quarters ago')
    assert_equal 'last week', result[:period]
  end

  test 'top_items is an array' do
    result = call_tool(period: 'this month')
    assert_kind_of Array, result[:top_items]
  end

  test 'total_revenue_formatted is a string' do
    result = call_tool(period: 'today')
    assert_kind_of String, result[:total_revenue_formatted]
  end

  private

  def call_tool(period:, item_name: nil)
    Agents::Tools::ReadOrderAnalytics.call(
      'restaurant_id' => @restaurant.id,
      'period'        => period,
      'item_name'     => item_name,
    )
  end
end
