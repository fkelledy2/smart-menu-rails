class AddVoiceOrderingEnabledToMenus < ActiveRecord::Migration[7.1]
  def change
    add_column :menus, :voiceOrderingEnabled, :boolean, default: false
  end
end
