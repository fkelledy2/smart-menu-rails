class AddStatusToMenusettings < ActiveRecord::Migration[7.1]
  def change
    add_column :menuavailabilities, :status, :integer
    add_column :menuavailabilities, :sequence, :integer
  end
end
