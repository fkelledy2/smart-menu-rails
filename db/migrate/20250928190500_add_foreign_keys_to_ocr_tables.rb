class AddForeignKeysToOcrTables < ActiveRecord::Migration[7.1]
  def change
    unless foreign_key_exists?(:ocr_menu_sections, :ocr_menu_imports, column: :ocr_menu_import_id)
      add_foreign_key :ocr_menu_sections, :ocr_menu_imports, column: :ocr_menu_import_id
    end

    unless foreign_key_exists?(:ocr_menu_items, :ocr_menu_sections, column: :ocr_menu_section_id)
      add_foreign_key :ocr_menu_items, :ocr_menu_sections, column: :ocr_menu_section_id
    end
  end
end
