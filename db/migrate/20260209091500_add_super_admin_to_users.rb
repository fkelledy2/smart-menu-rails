class AddSuperAdminToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :super_admin, :boolean, default: false, null: false
    add_index :users, [:admin, :super_admin]

    reversible do |dir|
      dir.up do
        migration_user = Class.new(ActiveRecord::Base) do
          self.table_name = 'users'
        end

        migration_user.reset_column_information
        migration_user.where(email: 'admin@mellow.menu').update_all(super_admin: true, admin: true)
      end
    end
  end
end
