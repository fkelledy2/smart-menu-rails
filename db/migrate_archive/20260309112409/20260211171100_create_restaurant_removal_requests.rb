class CreateRestaurantRemovalRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurant_removal_requests do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.string :requested_by_email, null: false
      t.integer :source, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :reason
      t.text :admin_notes
      t.datetime :actioned_at
      t.references :actioned_by_user, null: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :restaurant_removal_requests, %i[restaurant_id status]
  end
end
