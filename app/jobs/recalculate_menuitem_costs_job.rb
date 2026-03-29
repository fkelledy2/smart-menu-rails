class RecalculateMenuitemCostsJob < ApplicationJob
  queue_as :default

  def perform(ingredient_id)
    ingredient = Ingredient.find_by(id: ingredient_id)
    return unless ingredient

    # Find all menu items using this ingredient
    menuitem_ids = MenuitemIngredientQuantity.where(ingredient_id: ingredient_id).pluck(:menuitem_id).uniq

    menuitem_ids.each do |menuitem_id|
      menuitem = Menuitem.find_by(id: menuitem_id)
      next unless menuitem
      next unless menuitem.menuitem_costs.where(cost_source: 'recipe_calculated', is_active: true).any?

      # Recalculate recipe cost
      new_recipe_cost = menuitem.calculate_recipe_cost

      # Create new cost record with updated ingredient costs
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
