class CreateMenusectionlocales < ActiveRecord::Migration[7.1]
  def change
    create_table :menusectionlocales do |t|
      t.string :locale
      t.integer :status
      t.string :name
      t.string :description
      t.references :menusection, null: false, foreign_key: true

      t.timestamps
    end
  end
end
