class CreateMenuitemTagMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :menuitem_tag_mappings do |t|
      t.references :menuitem, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
