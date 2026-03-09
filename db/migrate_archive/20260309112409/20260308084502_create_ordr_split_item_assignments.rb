class CreateOrdrSplitItemAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :ordr_split_item_assignments do |t|
      t.references :ordr_split_plan, null: false, foreign_key: true
      t.references :ordr_split_payment, null: false, foreign_key: true
      t.references :ordritem, null: false, foreign_key: true

      t.timestamps
    end

    add_index :ordr_split_item_assignments, %i[ordr_split_plan_id ordritem_id], unique: true, name: 'idx_split_item_assignments_on_plan_and_item'
    add_index :ordr_split_item_assignments, %i[ordr_split_payment_id ordritem_id], unique: true, name: 'idx_split_item_assignments_on_payment_and_item'
  end
end
