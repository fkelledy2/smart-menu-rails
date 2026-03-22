require 'test_helper'

class InventoryProfitAnalyzerServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @service = InventoryProfitAnalyzerService.new(@restaurant)
  end

  test 'initializes with a restaurant' do
    assert_equal @restaurant, @service.instance_variable_get(:@restaurant)
  end

  test 'high_margin_low_stock_items returns an array' do
    result = @service.high_margin_low_stock_items
    assert_kind_of Array, result
  end

  test 'out_of_stock_profitable_items returns an array' do
    result = @service.out_of_stock_profitable_items
    assert_kind_of Array, result
  end

  test 'reorder_suggestions returns an array' do
    result = @service.reorder_suggestions
    assert_kind_of Array, result
  end

  test 'high_margin_low_stock_items items have expected keys when not empty' do
    result = @service.high_margin_low_stock_items
    result.each do |item|
      assert_includes item.keys, :menuitem
      assert_includes item.keys, :margin_percentage
      assert_includes item.keys, :profit_per_unit
      assert_includes item.keys, :stock_level
      assert_includes item.keys, :status
      assert_includes item.keys, :priority
    end
  end

  test 'reorder_suggestions items have expected keys when not empty' do
    result = @service.reorder_suggestions
    result.each do |suggestion|
      assert_includes suggestion.keys, :menuitem
      assert_includes suggestion.keys, :suggested_quantity
      assert_includes suggestion.keys, :estimated_profit_impact
      assert_includes suggestion.keys, :urgency
    end
  end

  test 'reorder_suggestions urgency values are valid' do
    result = @service.reorder_suggestions
    valid_urgencies = %w[high medium low]
    result.each do |suggestion|
      assert_includes valid_urgencies, suggestion[:urgency]
    end
  end
end
