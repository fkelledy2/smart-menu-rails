class AddNameToMenuSources < ActiveRecord::Migration[7.2]
  def change
    add_column :menu_sources, :name, :string
  end
end
