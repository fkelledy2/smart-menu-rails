# frozen_string_literal: true

class CreateDiningPatterns < ActiveRecord::Migration[7.2]
  def change
    create_table :dining_patterns do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.integer :party_size, null: false
      t.integer :day_of_week, null: false  # 0=Sunday, 6=Saturday (matching Ruby wday)
      t.integer :hour_of_day, null: false  # 0–23
      t.float :average_duration_minutes, null: false
      t.float :median_duration_minutes, null: false
      t.float :min_duration_minutes
      t.float :max_duration_minutes
      t.integer :sample_count, null: false, default: 0
      t.datetime :last_calculated_at, null: false

      t.timestamps
    end

    add_index :dining_patterns,
      [:restaurant_id, :party_size, :day_of_week, :hour_of_day],
      unique: true,
      name: 'idx_dining_patterns_lookup'

    add_check_constraint :dining_patterns,
      'day_of_week >= 0 AND day_of_week <= 6',
      name: 'dining_patterns_day_of_week_range'

    add_check_constraint :dining_patterns,
      'hour_of_day >= 0 AND hour_of_day <= 23',
      name: 'dining_patterns_hour_of_day_range'

    add_check_constraint :dining_patterns,
      'party_size > 0',
      name: 'dining_patterns_party_size_positive'

    add_check_constraint :dining_patterns,
      'sample_count >= 0',
      name: 'dining_patterns_sample_count_non_negative'
  end
end
