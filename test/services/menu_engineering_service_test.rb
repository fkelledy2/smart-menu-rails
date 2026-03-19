# frozen_string_literal: true
require 'test_helper'

class MenuEngineeringServiceTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @user = users(:one)
    
    # Create menu structure
    @menu = @restaurant.menus.create!(name: 'Test Menu', status: :active)
    @section = @menu.menusections.create!(name: 'Mains')
    
    # Create test items with costs
    @star_item = create_menuitem_with_cost('Star Item', 20.00, 5.00)
    @plowhorse_item = create_menuitem_with_cost('Plowhorse Item', 10.00, 8.00)
    @puzzle_item = create_menuitem_with_cost('Puzzle Item', 25.00, 8.00)
    @dog_item = create_menuitem_with_cost('Dog Item', 12.00, 10.00)
    
    # Create orders with different sales volumes
    create_orders_for_item(@star_item, 50, 20.00)
    create_orders_for_item(@plowhorse_item, 45, 10.00)
    create_orders_for_item(@puzzle_item, 5, 25.00)
    create_orders_for_item(@dog_item, 3, 12.00)
  end

  test 'analyzes menu and classifies items correctly' do
    service = MenuEngineeringService.new(@restaurant)
    result = service.analyze
    
    assert_not_nil result
    assert result[:stars].any?
    assert result[:plowhorses].any?
    assert result[:puzzles].any?
    assert result[:dogs].any?
  end

  test 'generates recommendations for each category' do
    service = MenuEngineeringService.new(@restaurant)
    result = service.analyze
    
    assert result[:recommendations].any?
    assert result[:recommendations].any? { |r| r[:category] == :stars }
    assert result[:recommendations].any? { |r| r[:category] == :plowhorses }
  end

  test 'calculates thresholds correctly' do
    service = MenuEngineeringService.new(@restaurant)
    result = service.analyze
    
    assert result[:thresholds][:popularity] > 0
    assert result[:thresholds][:profitability] > 0
  end

  test 'provides summary statistics' do
    service = MenuEngineeringService.new(@restaurant)
    result = service.analyze
    
    summary = result[:summary]
    assert_equal 4, summary[:total_items]
    assert summary[:total_profit] > 0
  end

  private

  def create_menuitem_with_cost(name, price, cost)
    item = @section.menuitems.create!(
      name: name,
      price: price,
      status: :active,
      restaurant: @restaurant
    )
    
    item.menuitem_costs.create!(
      ingredient_cost: cost * 0.6,
      labor_cost: cost * 0.2,
      packaging_cost: cost * 0.1,
      overhead_cost: cost * 0.1,
      total_cost: cost,
      effective_date: 30.days.ago,
      is_active: true,
      cost_source: 'manual'
    )
    
    item
  end

  def create_orders_for_item(menuitem, quantity, price)
    quantity.times do |i|
      order = @restaurant.ordrs.create!(
        user: @user,
        status: :completed,
        created_at: (30 - i).days.ago
      )
      
      order.ordritems.create!(
        menuitem: menuitem,
        quantity: 1,
        ordritemprice: price
      )
    end
  end
end
