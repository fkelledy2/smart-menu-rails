# frozen_string_literal: true

class AddUniqueIndexToGenimagesMenuitemId < ActiveRecord::Migration[7.2]
  def change
    # Drop the existing non-unique index first, then add a partial unique index.
    # The WHERE clause allows multiple rows with menuitem_id IS NULL (for menu/section images).
    remove_index :genimages, name: 'index_genimages_on_menuitem_id'
    add_index :genimages, :menuitem_id,
      unique: true,
      where: 'menuitem_id IS NOT NULL',
      name: 'index_genimages_on_menuitem_id_unique'
  end
end
