class AddAiModeToOcrMenuImports < ActiveRecord::Migration[7.1]
  def change
    add_column :ocr_menu_imports, :ai_mode, :integer, default: 0, null: false
  end
end
