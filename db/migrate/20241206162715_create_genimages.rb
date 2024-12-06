class CreateGenimages < ActiveRecord::Migration[7.1]
  def change
    create_table :genimages do |t|
      t.text :image_data
      t.string :name
      t.text :description
      t.references :restaurant, null: false, foreign_key: true
      t.references :menu, null: true, foreign_key: true
      t.references :menusection, null: true, foreign_key: true
      t.references :menuitem, null: true, foreign_key: true

      t.timestamps
    end
  end
end
