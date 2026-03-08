class CreateOrdrSplitPlans < ActiveRecord::Migration[7.2]
  def change
    create_table :ordr_split_plans do |t|
      t.references :ordr, null: false, foreign_key: true, index: { unique: true }
      t.integer :split_method, null: false, default: 0
      t.integer :plan_status, null: false, default: 0
      t.integer :participant_count, null: false, default: 0
      t.datetime :frozen_at
      t.references :created_by_user, foreign_key: { to_table: :users }
      t.references :updated_by_user, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :ordr_split_plans, :plan_status
  end
end
