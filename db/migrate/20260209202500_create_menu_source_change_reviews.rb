class CreateMenuSourceChangeReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :menu_source_change_reviews do |t|
      t.references :menu_source, null: false, foreign_key: true

      t.integer :status, null: false, default: 0
      t.datetime :detected_at, null: false

      t.string :previous_fingerprint
      t.string :new_fingerprint

      t.string :previous_etag
      t.string :new_etag

      t.datetime :previous_last_modified
      t.datetime :new_last_modified

      t.text :notes

      t.timestamps
    end

    add_index :menu_source_change_reviews, %i[menu_source_id status]
    add_index :menu_source_change_reviews, :detected_at
  end
end
