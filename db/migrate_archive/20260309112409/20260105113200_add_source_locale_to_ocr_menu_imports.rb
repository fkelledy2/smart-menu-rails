class AddSourceLocaleToOcrMenuImports < ActiveRecord::Migration[7.1]
  def change
    add_column :ocr_menu_imports, :source_locale, :string
    add_index :ocr_menu_imports, :source_locale
  end
end
