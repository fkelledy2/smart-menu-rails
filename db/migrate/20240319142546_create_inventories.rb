class CreateInventories < ActiveRecord::Migration[7.1]
  def change
    create_table :inventories do |t|
      t.integer :startinginventory
      t.integer :currentinventory
      t.integer :resethour
      t.references :menuitem, null: false, foreign_key: true

      t.timestamps
    end
  end
end
