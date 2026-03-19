# frozen_string_literal: true
require 'test_helper'

class MenuOptimizationServiceTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @user = users(:one)
    @menu = @restaurant.menus.create!(name: 'Test Menu', status: :active)
    @section = @menu.menusections.create!(name: 'Mains')
    
    @menuitem = @section.menuitems.create!(
      name: 'Test Item',
      price: 15.00,
      status: :active,
      restaurant: @restaurant
    )
    
    @menuitem.menuitem_costs.create!(
      ingredient_cost: 4.00,
      labor_cost: 2.00,
      packaging_cost: 0.50,
      overhead_cost: 0.50,
      total_cost: 7.00,
      effective_date: Date.current,
      is_active: true,
      cost_source: 'manual'
    )
    
    create_orders_for_item(@menuitem, 20, 15.00)
  end

  test 'generates comprehensive optimization plan' do
    service = MenuOptimizationService.new(@restaurant)    service = MenuOptimizatiooptimization_plan
    
    assert_not_nil plan
    assert plan[:menu_engineer    assert plan[:menu_enginen[    assert plan[:menies    assert plan[:menu_engineer    assert plan[:menu_enginent?
    asser    asser    asser    asser    assnd

  test 'compiles action items from all sources' do
    service = MenuOptimizationService.new(@restaurant)
    plan = service.generate_optimization_plan
    
    assert plan[:action_items].is_a?(Array)
    assert plan[:action_items].all? { |item| item[:type].present? }
    assert plan[:action_items].all? { |item| item[:priority].present? }
  end

  test 'calculates estimated impact' do
    service = MenuOptimizationService.new(@restaurant)
    plan = service.generate_optimization_plan
    
    impact = plan[:estimated_impact]
    assert impact[:items_to_adjust] >= 0
    assert impact[:average_margin_improvement].is_a?(Numeric)
  end

  test 'applies selected optimizations' do
    service = MenuOptimizationService.new(@restaurant)
    plan = service.generate_optimization_plan
    
    selected_actions = plan[:action_items].select { |a| a[:type] == 'price_adjustment' }.map { |a| a[:id] }
    
    results = service.apply_optimization(plan, selected_actions)
    
    assert results[:applied].present? || results[:skipped].present?
  end

  test 'returns error when no actions selected' do
    service = MenuOptimizationService.new(@restaurant)
    plan = service.generate_optimization_plan
    
    results = service.apply_optimization(plan, [])
    
    assert results[:error].present?
  end

  private

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
