class AddProvisionAndOrderingFieldsToRestaurants < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :provisioned_by, :integer, default: 0
    add_column :restaurants, :source_url, :string
    add_column :restaurants, :ordering_enabled, :boolean, default: false, null: false
    add_column :restaurants, :payments_enabled, :boolean, default: false, null: false
  end
end
