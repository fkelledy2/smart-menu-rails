class AddArchivalAuditColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :restaurants, :archived_at, :datetime
    add_column :restaurants, :archived_reason, :string
    add_column :restaurants, :archived_by_id, :bigint

    add_column :menus, :archived_at, :datetime
    add_column :menus, :archived_reason, :string
    add_column :menus, :archived_by_id, :bigint

    add_column :restaurant_menus, :archived_at, :datetime
    add_column :restaurant_menus, :archived_reason, :string
    add_column :restaurant_menus, :archived_by_id, :bigint

    add_index :restaurants, :archived_by_id
    add_index :menus, :archived_by_id
    add_index :restaurant_menus, :archived_by_id

    add_foreign_key :restaurants, :users, column: :archived_by_id
    add_foreign_key :menus, :users, column: :archived_by_id
    add_foreign_key :restaurant_menus, :users, column: :archived_by_id
  end
end
