class CreateAlcoholPolicies < ActiveRecord::Migration[7.0]
  def change
    create_table :alcohol_policies, if_not_exists: true do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.integer :allowed_days_of_week, array: true, default: [] # 0=Sunday .. 6=Saturday
      t.jsonb :allowed_time_ranges, default: [] # [{"from_min": 690, "to_min": 1380}]
      t.date :blackout_dates, array: true, default: []
      t.timestamps
    end

    unless index_exists?(:alcohol_policies, :restaurant_id)
      add_index :alcohol_policies, :restaurant_id, unique: true
    end
  end
end
