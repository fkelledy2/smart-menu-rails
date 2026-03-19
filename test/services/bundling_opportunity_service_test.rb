# frozen_string_literal: true
require 'test_helper'

class BundlingOpportunityServiceTest < ActiveSupport::TestCase
  setup do
    @restaurant = restaurants(:one)
    @user = users(:one)
    @menu = @restaurant.menus.create!(name: 'Test Menu', status: :active)
    @section = @menu.menusections.create!(name: 'Mains')
    
    @item1 = create_menuitem_with_cost('Burger', 12.00, 5.00)
    @item2 = create_menuitem_with_cost('Fries', 4.00, 1.50)
    @item3 = create_menuitem_with_cost('Drink', 3.00, 0.80)
    
    create_bundled_orders(@item1, @item2, 10)
    create_bundled_orders(@item1, @item3, 8)
    create_bundled_orders(@item2, @item3, 5)
  end

  test 'identifies frequently ordered together items' do
    service = BundlingOpportunityService.new(@restaurant)
    result = service.analyze
    
    assert result[:bundle_opportunities].any?
    assert result[:total_orders_analyzed] > 0
  end

                                                                                                                        ervice.analyze
    
    bundle = result[:bundle_opportunities].first
    assert bundle[:suggested_bundle_price] < bundle[:individual_total]
    assert_equal 10.0, bundle[:discount_percentage]
  end

  test 'provides summary statistics' do
    service = BundlingOpportunityService.new(@restaurant)
    result = service.analyze
    
    summary = result[:summary]
    assert summary[:total_opportunities] > 0
    assert summary[:total_potential_revenue] >= 0
  end

  test 'calculates appeal score for opportunities' do
    service = BundlingOpportunityService.new(@restaurant)
    result = service.analyze
    
    bundle = result[:bundle_opportunities].first
    assert bundle[:appeal_score] > 0
  end

  private

  def create_menuitem_with_cost(name, price, cost)
    item = @section.menuitems.create!(
      name: name,
      price: price,
      status: :active,
      restaurant: @restaurant
    )
                                                                                                                                        ,
      overhead_cost: cost * 0.05,
      total_cost: cost,
      effective_date: Date.current,
      is_active: true,
      cost_source: 'manual'
    )
    
    item
  end

  def create_bundled_orders(item1, item2, count)
    count.times do |i|
      order = @restaurant.ordrs.create!(
        user: @user,
        status: :completed,
        created_at: (30 - i).days.ago
      )
      
      order.ordritems.create!(menuitem: item1, quantity: 1, ordritemprice: item1.price)
      order.ordritems.create!(menuitem: item2, quantity: 1, ordritemprice: item2.price)
    end
  end
end
