class AddCascadeToMenuitemMappingFks < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :menuitem_ingredient_mappings, :ingredients
    add_foreign_key :menuitem_ingredient_mappings, :ingredients, column: :ingredient_id, on_delete: :cascade

    remove_foreign_key :menuitem_ingredient_mappings, :menuitems
    add_foreign_key :menuitem_ingredient_mappings, :menuitems, column: :menuitem_id, on_delete: :cascade

    remove_foreign_key :menuitem_tag_mappings, :menuitems
    add_foreign_key :menuitem_tag_mappings, :menuitems, column: :menuitem_id, on_delete: :cascade

    remove_foreign_key :menuitem_tag_mappings, :tags
    add_foreign_key :menuitem_tag_mappings, :tags, column: :tag_id, on_delete: :cascade
  end
end
