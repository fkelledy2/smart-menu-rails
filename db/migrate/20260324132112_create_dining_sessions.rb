class CreateDiningSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :dining_sessions do |t|
      t.references :smartmenu, null: false, foreign_key: true
      t.references :tablesetting, null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.string :session_token, limit: 64, null: false
      t.string :ip_address
      t.string :user_agent_hash, limit: 64
      t.boolean :active, null: false, default: true
      t.datetime :expires_at, null: false
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :dining_sessions, :session_token, unique: true, name: 'index_dining_sessions_on_session_token'
    add_index :dining_sessions, [:smartmenu_id, :active], name: 'index_dining_sessions_on_smartmenu_active'
    add_index :dining_sessions, [:tablesetting_id, :active], name: 'index_dining_sessions_on_tablesetting_active'
    add_index :dining_sessions, :expires_at, name: 'index_dining_sessions_on_expires_at'
  end
end
