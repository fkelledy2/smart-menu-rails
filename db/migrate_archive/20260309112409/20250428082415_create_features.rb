class CreateFeatures < ActiveRecord::Migration[7.1]
  def change
    create_table :features do |t|
      t.string :key
      t.string :descriptionKey
      t.integer :status

      t.timestamps
    end
  end
end
