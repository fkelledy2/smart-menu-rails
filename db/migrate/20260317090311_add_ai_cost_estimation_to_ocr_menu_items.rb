class AddAiCostEstimationToOcrMenuItems < ActiveRecord::Migration[7.2]
  def change
    add_column :ocr_menu_items, :estimated_ingredient_cost, :decimal, precision: 10, scale: 4
    add_column :ocr_menu_items, :estimated_labor_cost, :decimal, precision: 10, scale: 4
    add_column :ocr_menu_items, :estimated_packaging_cost, :decimal, precision: 10, scale: 4
    add_column :ocr_menu_items, :estimated_overhead_cost, :decimal, precision: 10, scale: 4
    add_column :ocr_menu_items, :cost_estimation_confidence, :decimal, precision: 5, scale: 2
    add_column :ocr_menu_items, :ai_cost_notes, :text
  end
end
