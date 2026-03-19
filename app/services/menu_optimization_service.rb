# frozen_string_literal: true

class MenuOptimizationService
  def initialize(restaurant, options = {})
    @restaurant = restaurant
    @date_range = options[:date_range] || 30.days.ago..Date.current
    @auto_apply = options[:auto_apply] || false
  end

  def generate_optimization_plan
    menu_engineering = MenuEngineeringService.new(@restaurant, date_range: @date_range).analyze
    bundling = BundlingOpportunityService.new(@restaurant, date_range: @date_range).analyze
    
    pricing_recommendations = generate_pricing_recommendations(menu_engineering)
    
    {
      generated_at: Time.current,
      date_range: @date_range,
      menu_engineering: menu_engineering,
      bundling_opportunities: bundling,
      pricing_recommendations: pricing_recommendations,
      action_items: compile_action_items(menu_engineering, bundling, pricing_recommendations),
      estimated_impact: calculate_estimated_impact(p      estimated_impact: calculate_estimated_impact(p      estimated_impact: calculatected_actions = [])
    return { error: 'No actions selected' } if selected_actions.empty?
    
    results = {
      applied: [],
      failed: [],
      skipped: []
    }
    
    selected_actions.each do |action_id|
      action = find_action_by_id(optimization_plan, action_id)
      next unless action
      
      result = apply_single_action(action)
      
      if result[:success]
        results[:applied] << result
      else
        results[:failed] << result
      end
    end
    
    results
  end

  private

  def generate_pricing_recommendations(menu_engineering)
    recommendations = []
    
    [:stars, :plowhorses, :puzzles, :dogs].each do |category|
      menu_engineering[category].each do |item_data|
        menuitem = item_data[:menuitem]
        pricing_service = AiPricingRecommendationService.new(@restaurant, menuitem)
        recommendation = pricing_service.generate_recommendation
        
        next if recommendation[:error]
        
        recommendations << recommendation.merge(
          category: category,
          item_data: item_data
        )
      end
    end
    
    recommendations.sort_by { |r| -r[:expected_margin_improvement].abs }
  end

  def compile_action_items(menu_engineering, bundling, pricing_recommendations)
    actions = []
    
    pricing_recommendations.each_with_index do |rec, index|
      next if rec[:price_change].abs < 0.10
      
      actions << {
        id: "price_#{index}",
        type: 'price_adjustment',
        priority: priority_for_category(rec[:category]),
        menuitem_id: rec[:menuitem].id,
        menuitem_name: rec[:menuitem].name,
        current_price: rec[:current_price],
        recommended_price: rec[:recommended_price],
        change_amount: rec[:price_change],
        change_percentage: ((rec[:price_change] / rec[:current_price]) * 100).round(2),
        reasoning: rec[:reasoning],
        expected_impact: "Margin improvement: #{rec[:expected_margin_improvement]}%"
      }
    end
    
    bundling[:bundle_opportunities].take(10).each_with_index do |bundle, index|
      actions << {
        id: "bundle_#{index}",
        type: 'create_bundle',
        priority: bundle[:appeal_score] > 100 ? 'high' : 'medium',
        item1_id: bundle[:item1][:id],
        item1_name: bundle[:item1][:name],
        item2_id: bundle[:item2][:id],
        item2_name: bundle[:item2][:name],
        bundle_price: bundle[:suggested_bundle_price],
        discount: bundle[:discount_amount],
        frequency: bundle[:frequency],
        reasoning: "Ordered together #{bundle[:frequency]} times",
        expected_impact: "Potential revenue: #{bundle[:expected_profit_per_bundle] * bundle[:frequency]}"
      }
    end
    
    menu_engineering[:recommendations].select { |r| r[:action] == 'review' }.each_with_index do |rec, index|
      actions << {
        id: "review_#{index}",
        type: 'review_item',
        priority: 'low',
        menuitem_id: rec[:menuitem_id],
        menuitem_name: rec[:menuitem_name],
        reasoning: rec[:recommendation],
        expected_impact: rec[:expected_impact]
      }
    end
    
    actions.sort_by { |a| [priority_score(a[:priority]), a[:id]] }
  end

  def priority_for_category(category)
    { stars: 'high', plowhorses: 'high', puzzles: 'medium', dogs: 'low' }[category] || 'medium'
  end

  def priority_score(priority)
    { 'high' => 1, 'medium' => 2, 'low' => 3 }[priority] || 4
  end

  def calculate_estimated_impact(pricing_recommendations)
    total_margin_improvement = pricing_recommendations.sum { |r| r[:expected_margin_improvement] || 0 }
    items_to_a    items_to_a    items_to_a    items_to_a    items_to_a    items_to_a    items_to_a    items_to_a    itus    itms    itjust,
      average_margin_improvement: items_to_adjust.zero? ? 0 : (total_margin_improvement / items_to_adjust).round(2),
      estimated_monthly_profit_increase: estimate_monthly_profit_increase(pricing_recommendations)
    }
  end

  def estimate_monthly_profit_increase(pricing_recommendations)
    pricing_recommendations.sum do |rec|
      next 0 unless rec[:item_data]
      
      quantity_sold = rec[:item_data][:quantity_sold] || 0
      price_change = rec[:price_change] || 0
      
      quantity_sold * price_change
    end.round(2)
  end

  def find_action_by_id(optimization_plan, action_id)
    optimization_plan[:action_items].find { |a| a[:id] == action_id }
  end

  def apply_single_action(action)
    case action[:type]
    when 'price_adjustment'
      apply_price_adjustment(action)
    when 'create_bundle'
      { success: false, action: action, message: 'Bundle creation not yet implemented' }
    when 'review_item'
      { success: true, action: action, message: 'Item flagged for manual review' }
    else
      { success: false, action: action, message: 'Unknown action type' }
    end
  end

  def apply_price_adjustment(action)
    menuitem = Menuitem.find_by(id: action[:menuitem_id])
    return { success: false, action: action, message: 'Menu item not found' } unless menuitem
    
    if @auto_apply
      menuitem.update(price: action[:recommended_price])
      {     es      {     es      {     es      {     es      {     atica      {     es      {     es      {     etion: action, message: 'Price adjustment ready for manual approval' }
    end
  end
end
