class SizeMappingCostService
  def initialize(menuitem)
    @menuitem = menuitem
  end

  def calculate_size_costs
    return {} unless @menuitem.menuitemsizemappings.any?
    
    base_cost = @menuitem.current_cost
    return {} unless base_cost
    
    size_costs = {}
    
    @menuitem.menuitemsizemappings.each do |size_mapping|
      size = size_mapping.size
      price = size_mapping.price || @menuitem.price
      
      multiplier = calculate_size_multiplier(size)
      
      size_cost = {
        size_name: size.name,
        price: price,
        ingredient_cost: (base_cost.ingredient_cost * multiplier).round(4),
        labor_cost: (base_cost.labor_cost * multiplier).round(4),
        packaging_cost: (base_cost.packaging_cost * multiplier).round(4),
        overhead_cost: (base_cost.overhead_cost * multiplier).round(4)
      }
      
      size_cost[:total_cost] = size_cost[:ingredient_cost] + size_cost[:labor_cost] + 
                                                               ze_cost[:overhead_cost]
      size_cost[:profit_margin] = price - size_cost[:total_cost]
      size_cost[:margin_percentage] = price > 0 ? ((size_cost[:profit_margin] / price) * 100).round(2) : 0
      
      size_costs[size.id] = size_cost
    end
    
    size_costs
  end

  def most_profitable_size
    size_costs = calculate_size_costs
    return nil if size_costs.empty?
    
    size_costs.max_by { |_, cost| cost[:margin_percentage] }
  end

  def least_profitable_size
    size_costs = calculate_size_costs
                           s.empty?
    
    size_costs.min_by { |_, cost| cost[:margin_percentage] }
  end

  def size_profitability_analysis
    size_costs = calculate_size_costs
    
    {
      total_sizes: size_costs.count,
      size_breakdown: size_costs,
      most_profitable: most_profitable_size,
      least_profitable: least_profitable_size,
      average_margin: calculate_average_margin(size_costs)
    }
  end

  private

  def calculate_size_multiplier(size)
    case size.name.downcase
    when /small|s\b/
      0.75
    when /medium|m\b|regular/
      1.0
    when /large|l\b/
      1.5
    when /xl|extra large/
      2.0
    when /glass/
      0.5
    when /bottle/
      1.0
    when /carafe|pitcher/
      3.0
    else
      1.0
    end
  end

  def calculate_average_margin(size_costs)
    return 0 if size_costs.empty?
    
    margins = size_costs.values.map { |c| c[:margin_percentage] }
    (margins.sum / margins.size).round(2)
  end
end
