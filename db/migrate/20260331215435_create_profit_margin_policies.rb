class CreateProfitMarginPolicies < ActiveRecord::Migration[7.2]
  def change
    create_table :profit_margin_policies do |t|
      t.string :key, null: false
      t.decimal :target_gross_margin_pct, precision: 5, scale: 2, null: false, default: 60.0
      t.decimal :floor_gross_margin_pct, precision: 5, scale: 2, null: false, default: 40.0
      t.integer :status, null: false, default: 0
      t.bigint :created_by_user_id

      t.timestamps
    end

    add_index :profit_margin_policies, :key, unique: true
    add_index :profit_margin_policies, :status
  end
end
