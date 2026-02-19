class CreateLocalGuides < ActiveRecord::Migration[7.2]
  def change
    create_table :local_guides do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :city, null: false
      t.string :country, null: false
      t.string :category
      t.text :content, null: false
      t.text :content_source
      t.jsonb :referenced_restaurants, default: []
      t.jsonb :faq_data, default: []
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.datetime :regenerated_at
      t.bigint :approved_by_user_id

      t.timestamps
    end

    add_index :local_guides, :slug, unique: true
    add_index :local_guides, :status
    add_index :local_guides, [:city, :category]
    add_index :local_guides, :approved_by_user_id
  end
end
