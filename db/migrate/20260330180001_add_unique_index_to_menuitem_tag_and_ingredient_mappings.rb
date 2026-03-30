class AddUniqueIndexToMenuitemTagAndIngredientMappings < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :menuitem_tag_mappings, %i[menuitem_id tag_id],
              unique: true,
              algorithm: :concurrently,
              name: 'index_menuitem_tag_mappings_on_menuitem_id_and_tag_id',
              if_not_exists: true

    add_index :menuitem_ingredient_mappings, %i[menuitem_id ingredient_id],
              unique: true,
              algorithm: :concurrently,
              name: 'idx_menuitem_ingredient_mappings_unique',
              if_not_exists: true
  end
end
