# frozen_string_literal: true

class CreateCustomerWaitQueues < ActiveRecord::Migration[7.2]
  def change
    create_table :customer_wait_queues do |t|
      t.references :restaurant, null: false, foreign_key: true
      t.string :customer_name, null: false
      t.string :customer_phone
      t.integer :party_size, null: false
      t.datetime :joined_queue_at, null: false
      t.integer :estimated_wait_minutes
      t.datetime :estimated_seat_time
      t.integer :queue_position, null: false
      t.string :status, null: false, default: 'waiting'
      t.datetime :seated_at
      t.bigint :tablesetting_id

      t.timestamps
    end

    add_index :customer_wait_queues, [:restaurant_id, :status]
    add_index :customer_wait_queues, [:restaurant_id, :joined_queue_at]
    add_index :customer_wait_queues, :tablesetting_id

    add_check_constraint :customer_wait_queues,
      "status IN ('waiting', 'notified', 'seated', 'cancelled', 'no_show')",
      name: 'customer_wait_queues_status_check'

    add_check_constraint :customer_wait_queues,
      'party_size > 0',
      name: 'customer_wait_queues_party_size_positive'

    add_check_constraint :customer_wait_queues,
      'queue_position > 0',
      name: 'customer_wait_queues_queue_position_positive'
  end
end
