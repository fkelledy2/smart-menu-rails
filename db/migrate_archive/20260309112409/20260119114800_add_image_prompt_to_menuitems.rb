class AddImagePromptToMenuitems < ActiveRecord::Migration[7.2]
  def change
    add_column :menuitems, :image_prompt, :text
  end
end
