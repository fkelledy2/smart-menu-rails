class CreateHerokuAddonPlanCosts < ActiveRecord::Migration[7.2]
  def change
    create_table :heroku_addon_plan_costs do |t|
      t.string :addon_service, null: false
      t.string :plan_name, null: false
      t.integer :cost_cents_per_month, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :heroku_addon_plan_costs, %i[addon_service plan_name], unique: true
  end
end
