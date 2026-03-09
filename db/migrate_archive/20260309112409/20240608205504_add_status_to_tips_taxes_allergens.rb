class AddStatusToTipsTaxesAllergens < ActiveRecord::Migration[7.1]
  def change
    add_column :tips, :status, :integer, :default => 0

    add_column :taxes, :status, :integer, :default => 0

    add_column :allergyns, :status, :integer, :default => 0
    add_column :allergyns, :sequence, :integer

    add_column :sizes, :status, :integer, :default => 0
    add_column :sizes, :sequence, :integer

    add_column :restaurants, :sequence, :integer
    add_column :employees, :sequence, :integer

    add_column :inventories, :status, :integer, :default => 0
    add_column :inventories, :sequence, :integer

  end
end
