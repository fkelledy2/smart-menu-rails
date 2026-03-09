class AddWifiDetailsToRestaurant < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :wifissid, :string
    add_column :restaurants, :wifiEncryptionType, :integer, default: 0
    add_column :restaurants, :wifiPassword, :string
    add_column :restaurants, :wifiHidden, :boolean, default: false
  end
end
