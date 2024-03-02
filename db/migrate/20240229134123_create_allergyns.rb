class CreateAllergyns < ActiveRecord::Migration[7.1]
  def change
    create_table :allergyns do |t|
      t.string :name
      t.text :description
      t.string :symbol
      t.references :menuitem, null: false, foreign_key: true

      t.timestamps
    end
  end
end
