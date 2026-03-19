# frozen_string_literal: true

# Menu Engineering Matrix Service
# Classifies menu items into 4 quadrants based on profitability and popularity:
# - Stars: High profit, High popularity (promote heavily)
# - Plowhorses: Low profit, High popularity (increase price or reduce cost)
# - Puzzles: High profit, Low popularity (promote more, improve visibility)
# - Dogs: Low profit, Low popularity (consider removing or repositioning)
class MenuEngineeringService
  def initialize(restaurant, date_range: 30.days.ago..Date.current)
    @restaurant = restaurant
    @date_range = date_range
  end

  def analyze
    items_with_data = fetch_items_with_sales_and_costs
    return empty_result if items_with_data.empty?

    popularity_threshold = calculate_popularity_threshold(items_with_data)
    profitability_threshold = calculate_profitability_threshold(items_with_data)

    classified_items = classify_items(items_with_data, popularity_threshold, profitability_threshold)

    {
      stars: classified_items[:stars],
      plowhorses: classified_items[:plowhorses],
      puzzles: classified_items[:puzzles],
      dogs: classified_items[:dogs],
      thresholds: {
        popularity: popularity_threshold,
        profitability: profitability_threshold
      },
      summary: generate_summary(classified_items),
      recommendations: generate_recommendations(classified_items)
    }
  end

  def item_classification(menuitem)
    items_with_data = fetch_items_with_sales_and_costs
    return nil if items_with_data.empty?

    item_data = items_with_data.find { |i| i[:menuitem].id == menuitem.id }
    return nil unless item_data

    popularity_threshold = calculate_popularity_threshold(items_with_data)
    profitability_threshold = calculate_profitability_threshold(items_with_data)

    classify_single_item(item_data, popularity_threshold, profitability_threshold)
  end

  private

  def fetch_items_with_sales_and_costs
    menuitems = @restaurant.menus
      .includes(menusections: { menuitems: %i[menuitem_costs profit_margin_target] })
      .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
      .select(&:has_cost_data?)

    orders = @restaurant.ordrs.where(created_at: @date_range).includes(:ordritems)
    
    sales_data = calculate_sales_data(orders)

    menuitems.map do |menuitem|
      sales = sales_data[menuitem.id] || { quantity: 0, revenue: 0 }
      next if sales[:quantity].zero?

      {
        menuitem: menuitem,
        quantity_sold: sales[:quantity],
        revenue: sales[:revenue],
        profit_margin: menuitem.profit_margin,
        profit_margin_percentage: menuitem.profit_margin_percentage,
        total_profit: menuitem.profit_margin * sales[:quantity],
        contribution_margin: menuitem.profit_margin * sales[:quantity]
      }
    end.compact
  end

  def calculate_sales_data(orders)
    sales = Hash.new { |h, k| h[k] = { quantity: 0, revenue: 0 } }

    orders.each do |order|
      order.ordritems.each do |item|
        next unless item.menuitem_id

        sales[item.menuitem_id][:quantity] += item.quantity
        sales[item.menuitem_id][:revenue] += (item.ordritemprice * item.quantity)
      end
    end

    sales
  end

  def calculate_popularity_threshold(items)
    quantities = items.map { |i| i[:quantity_sold] }
    median(quantities)
  end

  def calculate_profitability_threshold(items)
    margins = items.map { |i| i[:contribution_margin] }
    median(margins)
  end

  def median(array)
    return 0 if array.empty?
    
    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def classify_items(items, popularity_threshold, profitability_threshold)
    {
      stars: [],
      plowhorses: [],
      puzzles: [],
      dogs: []
    }.tap do |result|
      items.each do |item|
        category = classify_single_item(item, popularity_threshold, profitability_threshold)
        result[category] << item
      end
    end
  end

  def classify_single_item(item, popularity_threshold, profitability_threshold)
    high_popularity = item[:quantity_sold] >= popularity_threshold
    high_profitability = item[:contribution_margin] >= profitability_threshold

    if high_popularity && high_profitability
      :stars
    elsif high_popularity && !high_profitability
      :plowhorses
    elsif !high_popularity && high_profitability
      :puzzles
    else
      :dogs
    end
  end

  def generate_summary(classified_items)
    total_items = classified_items.values.flatten.count

    {
      total_items: total_items,
      stars_count: classified_items[:stars].count,
      stars_percentage: percentage(classified_items[:stars].count, total_items),
      plowhorses_count: classified_items[:plowhorses].count,
      plowhorses_percentage: percentage(classified_items[:plowhorses].count, total_items),
      puzzles_count: classified_items[:puzzles].count,
      puzzles_percentage: percentage(classified_items[:puzzles].count, total_items),
      dogs_count: classified_items[:dogs].count,
      dogs_percentage: percentage(classified_items[:dogs].count, total_items),
      total_profit: classified_items.values.flatten.sum { |i| i[:total_profit] }
    }
  end

  def generate_recommendations(classified_items)
    recommendations = []

    # Stars: Promote heavily, maintain quality
    classified_items[:stars].each do |item|
      recommendations << {
        menuitem_id: item[:menuitem].id,
        menuitem_name: item[:menuitem].name,
        category: :stars,
        priority: :high,
        action: 'promote',
        recommendation: 'Feature prominently on menu. Maintain quality and consistency. Consider slight price increase.',
        expected_impact: 'Maximize revenue from best performers'
      }
    end

    # Plowhorses: Increase price or reduce cost
    classified_items[:plowhorses].each do |item|
      recommendations << {
        menuitem_id: item[:menuitem].id,
        menuitem_name: item[:menuitem].name,
        category: :plowhorses,
        priority: :medium,
        action: 'optimize_cost',
        recommendation: "Popular but low margin (#{item[:profit_margin_percentage].round(1)}%). Consider: 1) Increase price by 5-10%, 2) Reduce ingredient costs, 3) Adjust portion size.",
        expected_impact: 'Improve profitability without losing popularity'
      }
    end

    # Puzzles: Promote more, improve visibility
    classified_items[:puzzles].each do |item|
      recommendations << {
        menuitem_id: item[:menuitem].id,
        menuitem_name: item[:menuitem].name,
        category: :puzzles,
        priority: :medium,
        action: 'promote',
        recommendation: "High margin (#{item[:profit_margin_percentage].round(1)}%) but low sales. Improve menu placement, add description, train staff to recommend.",
        expected_impact: 'Increase sales of high-margin items'
      }
    end

    # Dogs: Consider removing or repositioning
    classified_items[:dogs].each do |item|
      recommendations << {
        menuitem_id: item[:menuitem].id,
        menuitem_name: item[:menuitem].name,
        category: :dogs,
        priority: :low,
        action: 'review',
        recommendation: "Low margin (#{item[:profit_margin_percentage].round(1)}%) and low sales. Consider: 1) Remove from menu, 2) Reposition/rebrand, 3) Significant price increase.",
        expected_impact: 'Free up menu space and kitchen resources'
      }
    end

    recommendations.sort_by { |r| [priority_score(r[:priority]), -r[:menuitem_id]] }
  end

  def priority_score(priority)
    { high: 1, medium: 2, low: 3 }[priority]
  end

  def percentage(count, total)
    return 0 if total.zero?
    ((count.to_f / total) * 100).round(1)
  end

  def empty_result
    {
      stars: [],
      plowhorses: [],
      puzzles: [],
      dogs: [],
      thresholds: { popularity: 0, profitability: 0 },
      summary: {
        total_items: 0,
        stars_count: 0,
        stars_percentage: 0,
        plowhorses_count: 0,
        plowhorses_percentage: 0,
        puzzles_count: 0,
        puzzles_percentage: 0,
        dogs_count: 0,
        dogs_percentage: 0,
        total_profit: 0
      },
      recommendations: []
    }
  end
end
