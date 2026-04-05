# frozen_string_literal: true

class CreateGuestRatings < ActiveRecord::Migration[7.2]
  def change
    create_table :guest_ratings do |t|
      t.references :ordr,       null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.integer    :stars,      null: false
      t.text       :comment
      t.string     :source,     null: false, default: 'in_app'

      t.timestamps
    end

    add_index :guest_ratings, [:ordr_id, :source], unique: true, name: 'index_guest_ratings_on_ordr_source'
    add_index :guest_ratings, [:restaurant_id, :stars]
    add_index :guest_ratings, :created_at

    # Constraint: stars must be 1–5
    add_check_constraint :guest_ratings, 'stars BETWEEN 1 AND 5', name: 'check_guest_ratings_stars_range'
  end
end
