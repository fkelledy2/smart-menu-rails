class CreateRestaurantSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurant_subscriptions do |t|
      t.references :restaurant, null: false, foreign_key: true, index: { unique: true }

      t.integer :status, null: false, default: 0
      t.string :stripe_customer_id
      t.string :stripe_subscription_id

      t.boolean :payment_method_on_file, null: false, default: false
      t.datetime :trial_ends_at
      t.datetime :current_period_end

      t.timestamps
    end

    add_index :restaurant_subscriptions, :stripe_customer_id
    add_index :restaurant_subscriptions, :stripe_subscription_id
  end
end
