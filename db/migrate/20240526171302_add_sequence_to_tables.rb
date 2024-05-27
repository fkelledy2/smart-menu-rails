class AddSequenceToTables < ActiveRecord::Migration[7.1]
  def change
      add_column :tablesettings, :sequence, :integer
  end
end
