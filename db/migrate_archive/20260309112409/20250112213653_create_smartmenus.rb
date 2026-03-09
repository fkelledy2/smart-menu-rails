class CreateSmartmenus < ActiveRecord::Migration[7.1]
  def change
    create_table :smartmenus do |t|
      t.string :slug, null: false
      t.references :restaurant, null: false, foreign_key: true
      t.references :menu, null: true, foreign_key: true
      t.references :tablesetting, null: true, foreign_key: true
      t.timestamps
    end
    add_index :smartmenus, :slug
  end
end
