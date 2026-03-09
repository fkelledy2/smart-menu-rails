class CreateVoiceCommands < ActiveRecord::Migration[7.2]
  def change
    create_table :voice_commands do |t|
      t.references :smartmenu, null: false, foreign_key: true
      t.string :session_id, null: false
      t.string :status, null: false, default: 'queued'
      t.string :locale
      t.text :transcript
      t.jsonb :intent
      t.jsonb :result
      t.text :error_message
      t.jsonb :context
      t.timestamps
    end

    add_index :voice_commands, [:smartmenu_id, :session_id, :created_at]
    add_index :voice_commands, :status
  end
end
