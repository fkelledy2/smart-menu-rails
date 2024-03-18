class CreateMenuitemSizeMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :menuitem_size_mappings do |t|
      t.references :menuitem, null: false, foreign_key: true
      t.references :size, null: false, foreign_key: true

      t.timestamps
    end
  end
end
