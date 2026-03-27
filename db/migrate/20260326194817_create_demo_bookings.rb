# frozen_string_literal: true

class CreateDemoBookings < ActiveRecord::Migration[7.2]
  def change
    create_table :demo_bookings do |t|
      t.string :restaurant_name, null: false
      t.string :contact_name,    null: false
      t.string :email,           null: false
      t.string :phone
      t.string :restaurant_type
      t.string :location_count
      t.text   :interests
      t.string :calendly_event_id
      t.string :conversion_status, null: false, default: 'pending'

      t.timestamps
    end

    add_index :demo_bookings, :email
    add_index :demo_bookings, :created_at
    add_index :demo_bookings, :conversion_status
  end
end
