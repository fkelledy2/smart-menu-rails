class AddDescriptionToMenusections < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:menusections, :description)
      add_column :menusections, :description, :text
    end
  end
end
