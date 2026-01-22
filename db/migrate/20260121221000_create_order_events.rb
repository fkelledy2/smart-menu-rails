class CreateOrderEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :order_events do |t|
      t.references :ordr, null: false, foreign_key: true
      t.bigint :sequence, null: false
      t.string :event_type, null: false
      t.string :entity_type, null: false
      t.bigint :entity_id
      t.jsonb :payload, null: false, default: {}
      t.string :source, null: false
      t.string :idempotency_key
      t.datetime :occurred_at, null: false, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :order_events, %i[ordr_id sequence], unique: true
    add_index :order_events, %i[ordr_id created_at id]
    add_index :order_events, %i[ordr_id idempotency_key], unique: true,
                                                        where: 'idempotency_key IS NOT NULL',
                                                        name: 'index_order_events_on_ordr_id_and_idempotency_key'
  end
end
