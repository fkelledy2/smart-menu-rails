class CreatePushSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :endpoint, null: false
      t.text :p256dh_key, null: false
      t.text :auth_key, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    
    add_index :push_subscriptions, :endpoint, unique: true
    add_index :push_subscriptions, [:user_id, :active]
  end
end
