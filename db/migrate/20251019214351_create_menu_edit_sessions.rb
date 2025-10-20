class CreateMenuEditSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :menu_edit_sessions do |t|
      t.references :menu, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.string :session_id, null: false
      t.json :locked_fields, default: []
      t.datetime :started_at
      t.datetime :last_activity_at

      t.timestamps
    end
    
    add_index :menu_edit_sessions, [:menu_id, :user_id], unique: true
    add_index :menu_edit_sessions, :session_id
    add_index :menu_edit_sessions, :last_activity_at
  end
end
