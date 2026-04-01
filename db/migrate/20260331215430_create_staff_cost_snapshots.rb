class CreateStaffCostSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :staff_cost_snapshots do |t|
      t.date :month, null: false
      t.string :currency, null: false, default: 'EUR'
      t.integer :support_cost_cents, null: false, default: 0
      t.integer :staff_cost_cents, null: false, default: 0
      t.integer :other_ops_cost_cents, null: false, default: 0
      t.text :notes
      t.bigint :created_by_user_id

      t.timestamps
    end

    add_index :staff_cost_snapshots, %i[month currency], unique: true
    add_index :staff_cost_snapshots, :month
  end
end
