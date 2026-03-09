class AddItemtypeToMenuitems < ActiveRecord::Migration[7.1]
  def change
    add_column :menuitems, :itemtype, :integer, default: 0
    add_column :menuitems, :sizesupport, :boolean, default: false
  end
end
