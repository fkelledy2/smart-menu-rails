class CreateUserSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :session_id, null: false
      t.string :resource_type
      t.bigint :resource_id
      t.string :status, default: 'active', null: false
      t.datetime :last_activity_at
      t.json :metadata, default: {}

      t.timestamps
    end
    
    add_index :user_sessions, :session_id, unique: true
    add_index :user_sessions, [:resource_type, :resource_id]
    add_index :user_sessions, [:user_id, :status]
    add_index :user_sessions, :last_activity_at
  end
end
