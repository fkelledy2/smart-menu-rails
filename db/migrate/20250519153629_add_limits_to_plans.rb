class AddLimitsToPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :plans, :itemspermenu, :integer, :default => 0
    add_column :plans, :languages, :integer, :default => 0
    add_column :plans, :locations, :integer, :default => 0
  end
end