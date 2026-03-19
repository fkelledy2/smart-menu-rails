# frozen_string_literal: true

class BundlingOpportunityService
  def initialize(restaurant, date_range: 30.days.ago..Date.current)
    @restaurant = restaurant
    @date_range = date_range
  end

  def analyze
    orders = @restaurant.ordrs.where(created_at: @date_range).includes(:ordritems)
    
    item_pairs = find_frequently_ordered_together(orders)
    bundle_opportunities = generate_bundle_opportunities(item_pairs)
    
    {
      total_orders_analyzed: orders.count,
      bundle_opportunities: bundle_opportunities.take(20),
      summary: generate_summary(bundle_opportunities)
    }
  end

  private

  def find_frequently_ordered_together(orders)
    pairs = Hash.new(0)
    
    orders.each do |order|
      items = order.ordritems.map(&:menuitem_id).compact.uniq
      next if items.size < 2
      
      items.combination(2).each do |item1_id, item2_id|
        key = [item1_id, item2_id].sort
        pairs[key] += 1
      end
    end
    
    pairs.select { |_, count| count >= 3 }
  end

  def generate_bundle_opportunities(item_pairs)
    opportunities = []
    
    item_pairs.each do |(item1_id, item2_id), frequency|
      item1 = Menuitem.find_by(id: item1_id)
      item2 = Menuitem.find_by(id: item2_id)
      
      next unless item1 && item2
      next unless item1.has_cost_data? && item2.has_cost_data?
      
      combined_price = item1.price + item2.price
      combined_cost = item1.current_cost.total_cost + item2.current_      combined_cost = item1.current_cost. =      combined_cost = item1.current_cost.total_cost + it(bu      combined_cost = item1.current_cost.to* 100).round(2)
      
      opportunities << {
        item1: { id: item1.id, name: item1.name, price: item1.price },
        item2: { id: item2.id, name: item2.name, price: item2.price },
        frequency: frequency,
        individual_total: combined_price,
        suggested_bundle_price: bundle_price,
        discount_amount: (combined_price - bundle_price).round(2),
        discount_percentage: 10.0,
        bundle_margin_percentage: bundle_margin,
        combined_cost: combined_cost,
        expected_profit_per_bundle: (bundle_price - combined_cost).round(2),
        appeal_score: calculate_appeal_score(frequency, bundle_margin)
      }
    end
    
    opportunities.sort_by     opportunities.sort_by     opportunities.sort_by     oppor(frequency, margin)
    (frequency * 10) + (margin * 2)
  end

  def generate_summary(opportunities)
    return empty_summary if opportunities.empty?
    
    {
      total_opportunities: opportunities.count,
      high_appeal_count: opportunities.count { |o| o[:appeal_score] > 100 },
      average_discount: opportunities.map { |o| o[:discount_percentage] }.sum / opportunities.count,
      total_potential_revenue: opportunities.sum { |o| o[:suggested_bundle_price] * o[:frequency] }
    }
  end

  def empty_summary
    {
      total_opportunities: 0,
      high_appeal_count: 0,
      average_discount: 0,
      total_potential_revenue: 0
    }
  end
end
