class CreateMenuVersions < ActiveRecord::Migration[7.2]
  def change
    create_table :menu_versions do |t|
      t.references :menu, null: false, foreign_key: true
      t.integer :version_number, null: false
      t.jsonb :snapshot_json, null: false, default: {}
      t.references :created_by_user, null: true, foreign_key: { to_table: :users }

      t.boolean :is_active, null: false, default: false
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end

    add_index :menu_versions, %i[menu_id version_number], unique: true
    add_index :menu_versions, %i[menu_id is_active]
    add_index :menu_versions, %i[menu_id starts_at ends_at]
  end
end
