class AddLimitsToPlans2 < ActiveRecord::Migration[7.1]
  def change
    add_column :plans, :menusperlocation, :integer, :default => 0
  end
end
