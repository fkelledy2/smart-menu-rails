class AddTypeToTablesettings < ActiveRecord::Migration[7.1]
  def change
    add_column :tablesettings, :type, :integer
  end
end
