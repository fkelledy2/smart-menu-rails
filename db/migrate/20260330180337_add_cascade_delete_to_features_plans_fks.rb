class AddCascadeDeleteToFeaturesPlansFks < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :features_plans, :features
    add_foreign_key :features_plans, :features, column: :feature_id, on_delete: :cascade

    remove_foreign_key :features_plans, :plans
    add_foreign_key :features_plans, :plans, column: :plan_id, on_delete: :cascade
  end
end
