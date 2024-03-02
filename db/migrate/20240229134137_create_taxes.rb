class CreateTaxes < ActiveRecord::Migration[7.1]
  def change
    create_table :taxes do |t|
      t.string :name
      t.integer :taxtype
      t.float :taxpercentage
      t.references :restaurant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
