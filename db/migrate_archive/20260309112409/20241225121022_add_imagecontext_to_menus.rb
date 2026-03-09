class AddImagecontextToMenus < ActiveRecord::Migration[7.1]
  def change
    add_column :menus, :imagecontext, :string
  end
end
