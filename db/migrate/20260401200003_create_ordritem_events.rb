class CreateOrdritemEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :ordritem_events do |t|
      t.bigint   :ordritem_id, null: false
      t.bigint   :ordr_id, null: false
      t.bigint   :restaurant_id, null: false
      t.string   :event_type, null: false
      t.integer  :from_status
      t.integer  :to_status
      t.datetime :occurred_at, null: false
      t.string   :actor_type
      t.bigint   :actor_id
      t.jsonb    :metadata, default: {}
      t.timestamps
    end

    add_index :ordritem_events, :ordritem_id
    add_index :ordritem_events, :ordr_id
    add_index :ordritem_events, :restaurant_id
    add_index :ordritem_events, :occurred_at
    add_index :ordritem_events, %i[ordr_id occurred_at]

    add_foreign_key :ordritem_events, :ordritems
    add_foreign_key :ordritem_events, :restaurants
  end
end
