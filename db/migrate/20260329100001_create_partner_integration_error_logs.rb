class CreatePartnerIntegrationErrorLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :partner_integration_error_logs do |t|
      t.bigint :restaurant_id, null: false
      t.string :adapter_type, null: false
      t.string :event_type, null: false
      t.jsonb :payload_json, null: false, default: {}
      t.text :error_message, null: false
      t.integer :attempt_number, null: false, default: 1

      t.timestamps default: -> { 'NOW()' }, null: false
    end

    add_index :partner_integration_error_logs, :restaurant_id
    add_index :partner_integration_error_logs, [:restaurant_id, :created_at],
              name: 'index_partner_int_error_logs_on_restaurant_created'
    add_index :partner_integration_error_logs, :adapter_type
    add_index :partner_integration_error_logs, :event_type

    add_foreign_key :partner_integration_error_logs, :restaurants
  end

  def down
    drop_table :partner_integration_error_logs
  end
end
