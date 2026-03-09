class CreateTracks < ActiveRecord::Migration[7.1]
  def change
    create_table :tracks do |t|
      t.string :externalid
      t.string :name
      t.text :description
      t.string :image
      t.integer :sequence
      t.references :restaurant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
