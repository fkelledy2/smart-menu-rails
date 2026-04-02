class CreateAgentDomainEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :agent_domain_events do |t|
      t.string :event_type, null: false
      t.string :source_type
      t.bigint :source_id
      t.jsonb :payload, null: false, default: {}
      t.string :idempotency_key, null: false
      t.datetime :processed_at

      t.timestamps
    end

    add_index :agent_domain_events, :idempotency_key, unique: true
    add_index :agent_domain_events, :event_type
    add_index :agent_domain_events, :processed_at
    add_index :agent_domain_events, [:source_type, :source_id], name: 'idx_agent_domain_events_source'
    add_index :agent_domain_events, :payload, using: :gin

    # Partial index for fast polling of unprocessed events
    add_index :agent_domain_events, :created_at,
      where: 'processed_at IS NULL',
      name: 'idx_agent_domain_events_unprocessed'
  end
end
