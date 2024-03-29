class RenameTypeInTablesettings < ActiveRecord::Migration[7.1]
  def change
    rename_column :tablesettings, :type, :tabletype
  end
end
