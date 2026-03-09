class AddLinksToOcrMenuModels < ActiveRecord::Migration[7.1]
  def change
    # Link OCR sections to modern menusections table
    add_column :ocr_menu_sections, :menusection_id, :bigint
    add_index  :ocr_menu_sections, :menusection_id
    add_foreign_key :ocr_menu_sections, :menusections, column: :menusection_id

    # Link OCR items to modern menuitems table
    add_column :ocr_menu_items, :menuitem_id, :bigint
    add_index  :ocr_menu_items, :menuitem_id
    add_foreign_key :ocr_menu_items, :menuitems, column: :menuitem_id
  end
end
