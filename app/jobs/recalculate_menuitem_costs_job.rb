class RecalculateMenuitemCostsJob < ApplicationJob
  queue_as :default

  def perform(ingredient_id)
    ingredient = Ingredient.find_by(id: ingredient_id)
    return unless ingredient

    # Find all menu items using this ingredient (single query, deduplicated)
    menuitem_ids = MenuitemIngredientQuantity.where(ingredient_id: ingredient_id).pluck(:menuitem_id).uniq
    return if menuitem_ids.empty?

    # Performance: load all affected menu items with their active recipe costs in two
    # queries instead of N individual find_by + association queries per item.
    menuitems = Menuitem.where(id: menuitem_ids).includes(:menuitem_costs).index_by(&:id)

    # Filter to only items that have at least one active recipe-calculated cost
    eligible_menuitems = menuitems.values.select do |mi|
      mi.menuitem_costs.any? { |c| c.cost_source == 'recipe_calculated' && c.is_active }
    end

    eligible_menuitems.each do |menuitem|
      new_recipe_cost = menuitem.calculate_recipe_cost

      # current_cost is derived from already-loaded menuitem_costs — no extra query
      current_cost = menuitem.current_cost
      next unless current_cost&.cost_source == 'recipe_calculated'

      MenuitemCost.create!(
        menuitem: menuitem,
        ingredient_cost: new_recipe_cost,
        labor_cost: current_cost.labor_cost,
        packaging_cost: current_cost.packaging_cost,
        overhead_cost: current_cost.overhead_cost,
        cost_source: 'recipe_calculated',
        effective_date: Date.current,
        is_active: true,
        notes: "Auto-updated due to ingredient cost change for #{ingredient.name}",
      )
    end
  end
end
