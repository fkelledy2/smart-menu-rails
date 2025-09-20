class AddSectionDescriptionAndDietaryFlags < ActiveRecord::Migration[7.1]
  def change
    # OcrMenuSection: optional description shown under section name
    unless column_exists?(:ocr_menu_sections, :description)
      add_column :ocr_menu_sections, :description, :text
    end

    # OcrMenuItem: dietary flags for UI badges and filtering
    unless column_exists?(:ocr_menu_items, :is_vegetarian)
      add_column :ocr_menu_items, :is_vegetarian, :boolean, default: false, null: false
    end
    unless column_exists?(:ocr_menu_items, :is_vegan)
      add_column :ocr_menu_items, :is_vegan, :boolean, default: false, null: false
    end
    unless column_exists?(:ocr_menu_items, :is_gluten_free)
      add_column :ocr_menu_items, :is_gluten_free, :boolean, default: false, null: false
    end
    unless column_exists?(:ocr_menu_items, :is_dairy_free)
      add_column :ocr_menu_items, :is_dairy_free, :boolean, default: false, null: false
    end
  end
end
