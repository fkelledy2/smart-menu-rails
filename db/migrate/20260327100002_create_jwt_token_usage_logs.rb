# frozen_string_literal: true

class CreateJwtTokenUsageLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :jwt_token_usage_logs do |t|
      t.references :jwt_token, null: false,
                   foreign_key: { to_table: :admin_jwt_tokens }, index: false
      t.string  :endpoint,        null: false
      t.string  :http_method,     null: false
      t.string  :ip_address
      t.integer :response_status, null: false

      t.datetime :created_at, null: false
    end

    # No updated_at — these are immutable log records
    add_index :jwt_token_usage_logs, [:jwt_token_id, :created_at],
              name: 'index_jwt_token_usage_logs_on_token_and_time'
    add_index :jwt_token_usage_logs, :created_at
  end
end
