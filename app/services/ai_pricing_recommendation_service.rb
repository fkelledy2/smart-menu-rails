# frozen_string_literal: true

class AiPricingRecommendationService
  def initialize(restaurant, menuitem)
    @restaurant = restaurant
    @menuitem = menuitem
  end

  def generate_recommendation
    return no_cost_data_result unless @menuitem.has_cost_data?

    classification = MenuEngineeringService.new(@restaurant).item_classification(@menuitem)
    
    {
      menuitem: @menuitem,
      current_price: @menuitem.price,
      current_cost: @menuitem.current_cost&.total_cost,
      current_margin: @menuitem.profit_margin,
      current_margin_percentage: @menuitem.profit_margin_percentage,
      classification: classification,
      recommended_price: calculate_recommended_price(classification),
      price_change: calculate_price_change,
      expected_margin_improvement: calculate_margin_improvement,
      confidence: calculate_confidence(classification),
      reasoning: generate_reasoning(classification)
    }
  end

  private

  def calculate_recommended_price(classification)
    current_price = @menuitem.price
    cost = @menuitem.current_cost&.total_cost || 0
    target_margin = @menuitem.effective_margin_target || 30

    case classification
    when :stars
      # Slight increase for stars
      current_price * 1.05
    when :plowhorses
      # Increase to improve margin
      [cost * (1 + target_margin / 100.0), current_price * 1.10].max
    when :puzzles
      # Keep price, focus on promotion
      current_price
    when :dogs
      # Significant increase or remove
      cost * (1 + target_margin / 100.0)
    else
      cost * (1 + target_margin / 100.0)
    end.round(2)
  end

  def calculate_price_change
    recommended = calculate_recommended_price(MenuEngineeringService.new(@restaurant).item_classification(@menuitem))
    (recommended - @menuitem.price).round(2)
  end

  def calculate_margin_improvement
    recommended = calculate_recommended_price(MenuEngineeringService.new(@restaurant).item_classification(@menuitem))
    cost = @menuitem.current_cost&.total_cost || 0
    new_margin = ((recommended - cost) / recommended * 100).round(2)
    (new_margin - @menuitem.profit_margin_percentage).round(2)
  end

  def calculate_confidence(classification)
    classification ? 'high' : 'medium'
  end

  def generate_reasoning(classification)
    case classification
    when :stars
      "High-performing item. Small price increase won't hurt demand."
    when :plowhorses
      "Popular but low margin. Price increase needed for profitability."
    when :puzzles
      "High margin, low sales. Focus on promotion, not pricing."
    when :dogs
      "Low performance. Significant price increase or consider removal."
    else
      "Standard cost-plus pricing based on target margin."
    end
  end

  def no_cost_data_result
    { error: 'No cost data available for this menu item' }
  end
end
