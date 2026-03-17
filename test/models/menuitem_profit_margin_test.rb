require 'test_helper'

class MenuitemProfitMarginTest < ActiveSupport::TestCase
  def setup
    @menuitem = menuitems(:one)
    @menuitem.update!(price: 15.00)
    @restaurant = @menuitem.menusection.menu.restaurant
    
    @cost = MenuitemCost.create!(
      menuitem: @menuitem,
      ingredient_cost: 3.00,
      labor_cost: 2.00,
      packaging_cost: 0.50,
      overhead_cost: 0.50,
      effective_date: Date.current,
      is_active: true
    )
  end

  test "should calculate profit margin in dollars" do
    assert_equal 9.00, @menuitem.profit_margin
  end

  test "should calculate profit margin percentage" do
    assert_equal 60.0, @menuitem.profit_margin_percentage
  end

  test "should return zero margin when no cost data" do
    @cost.destroy
    assert_equal 0, @menuitem.profit_margin
  end

  test "should get current active cost" do
    assert_equal @cost, @menuitem.current_cost
  end

  test "should check if item has cost data" do
    assert @menuitem.has_cost_data?
    
    @cost.destroy
    assert_not @menuitem.has_cost_data?
  end
end
