class CreateMenuitems < ActiveRecord::Migration[7.1]
  def change
    create_table :menuitems do |t|
      t.string :name
      t.text :description
      t.string :image
      t.integer :status
      t.integer :sequence
      t.integer :calories
      t.float :price
      t.references :menusection, null: false, foreign_key: true

      t.timestamps
    end
  end
end
