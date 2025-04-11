class CreateRestaurantlocales < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurantlocales do |t|
      t.string :locale
      t.integer :status
      t.references :restaurant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
