class CreatePlans < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.string :key
      t.string :descriptionKey
      t.string :attribute1
      t.string :attribute2
      t.string :attribute3
      t.string :attribute4
      t.string :attribute5
      t.string :attribut6
      t.integer :status
      t.boolean :favourite
      t.decimal :pricePerMonth
      t.decimal :pricePerYear
      t.integer :action

      t.timestamps
    end
  end
end
