class RemoveMenuitemfromTags < ActiveRecord::Migration[7.1]
  def change
    remove_column :tags, :menuitem_id, :integer
  end
end
