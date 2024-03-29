class CreateRestaurantavailabilities < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurantavailabilities do |t|
      t.integer :dayofweek
      t.integer :starthour
      t.integer :startmin
      t.integer :endhour
      t.integer :endmin
      t.references :restaurant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
