class AddTypeToTags < ActiveRecord::Migration[7.1]
  def change
    add_column :tags, :typs, :integer
  end
end
