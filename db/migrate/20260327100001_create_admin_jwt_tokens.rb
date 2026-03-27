# frozen_string_literal: true

class CreateAdminJwtTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :admin_jwt_tokens do |t|
      t.references :admin_user, null: false, foreign_key: { to_table: :users }, index: true
      t.references :restaurant, null: false, foreign_key: true, index: true
      t.string  :token_hash,   null: false
      t.string  :name,         null: false
      t.text    :description
      t.jsonb   :scopes,       null: false, default: []
      t.integer :rate_limit_per_minute, null: false, default: 60
      t.integer :rate_limit_per_hour,   null: false, default: 1000
      t.datetime :expires_at,  null: false
      t.datetime :revoked_at
      t.datetime :last_used_at
      t.integer  :usage_count, null: false, default: 0

      t.timestamps
    end

    add_index :admin_jwt_tokens, :token_hash, unique: true
    add_index :admin_jwt_tokens, [:restaurant_id, :revoked_at],
              name: 'index_admin_jwt_tokens_on_restaurant_active'
    add_index :admin_jwt_tokens, :expires_at

    # Check constraint: scopes must be a JSON array
    add_check_constraint :admin_jwt_tokens,
                         "jsonb_typeof(scopes) = 'array'",
                         name: 'check_admin_jwt_tokens_scopes_is_array'
  end
end
