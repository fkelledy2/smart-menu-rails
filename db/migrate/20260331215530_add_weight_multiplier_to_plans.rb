class AddWeightMultiplierToPlans < ActiveRecord::Migration[7.2]
  def change
    add_column :plans, :weight_multiplier, :decimal, precision: 6, scale: 2, default: 1.0, null: false
  end
end
