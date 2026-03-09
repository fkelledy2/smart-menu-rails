class CreateResourceLocks < ActiveRecord::Migration[7.2]
  def change
    create_table :resource_locks do |t|
      t.string :resource_type, null: false
      t.bigint :resource_id, null: false
      t.string :field_name
      t.references :user, null: false, foreign_key: true, index: true
      t.string :session_id, null: false
      t.datetime :acquired_at
      t.datetime :expires_at

      t.timestamps
    end
    
    add_index :resource_locks, [:resource_type, :resource_id, :field_name], 
              unique: true, name: 'index_resource_locks_on_resource_and_field'
    add_index :resource_locks, :expires_at
    add_index :resource_locks, :session_id
  end
end
