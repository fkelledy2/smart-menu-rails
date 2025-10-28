class CreateHeroImages < ActiveRecord::Migration[7.2]
  def change
    create_table :hero_images do |t|
      t.string :image_url, null: false
      t.string :alt_text
      t.integer :sequence, default: 0
      t.integer :status, default: 0, null: false
      t.string :source_url

      t.timestamps
    end
    
    add_index :hero_images, :status
    add_index :hero_images, :sequence
  end
end
