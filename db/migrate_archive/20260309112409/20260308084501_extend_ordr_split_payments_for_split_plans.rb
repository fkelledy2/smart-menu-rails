class ExtendOrdrSplitPaymentsForSplitPlans < ActiveRecord::Migration[7.2]
  def change
    change_table :ordr_split_payments do |t|
      t.references :ordr_split_plan, foreign_key: true
      t.integer :split_method
      t.integer :position
      t.integer :base_amount_cents, null: false, default: 0
      t.integer :tax_amount_cents, null: false, default: 0
      t.integer :tip_amount_cents, null: false, default: 0
      t.integer :service_charge_amount_cents, null: false, default: 0
      t.integer :percentage_basis_points
      t.datetime :locked_at
    end

    add_index :ordr_split_payments, [:ordr_split_plan_id, :position], unique: true
  end
end
