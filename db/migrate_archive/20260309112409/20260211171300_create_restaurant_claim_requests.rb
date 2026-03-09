class CreateRestaurantClaimRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurant_claim_requests do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.references :initiated_by_user, null: true, foreign_key: { to_table: :users }
      t.integer :status, null: false, default: 0
      t.integer :verification_method, null: false, default: 0
      t.string :claimant_email, null: false
      t.string :claimant_name
      t.text :evidence
      t.text :review_notes
      t.datetime :verified_at
      t.references :reviewed_by_user, null: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :restaurant_claim_requests, %i[restaurant_id status]
  end
end
