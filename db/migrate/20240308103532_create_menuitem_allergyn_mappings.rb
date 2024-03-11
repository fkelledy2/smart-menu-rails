class CreateMenuitemAllergynMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :menuitem_allergyn_mappings do |t|
      t.references :menuitem, null: false, foreign_key: true
      t.references :allergyn, null: false, foreign_key: true

      t.timestamps
    end
  end
end
