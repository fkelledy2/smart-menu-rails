class CreateMenusections < ActiveRecord::Migration[7.1]
  def change
    create_table :menusections do |t|
      t.string :name
      t.text :description
      t.string :image
      t.integer :status
      t.integer :sequence
      t.references :menu, null: false, foreign_key: true

      t.timestamps
    end
  end
end
