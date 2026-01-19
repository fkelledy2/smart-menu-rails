class AddImagePromptToOcrMenuItems < ActiveRecord::Migration[7.1]
  def change
    add_column :ocr_menu_items, :image_prompt, :text
  end
end
