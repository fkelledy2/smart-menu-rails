class CreateFeaturesPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :features_plans do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :feature, null: false, foreign_key: true
      t.string :featurePlanNote
      t.integer :status

      t.timestamps
    end
    # Optionally add a unique index to prevent duplicate entries
    add_index :features_plans, [:plan_id, :feature_id], unique: true
  end
end
