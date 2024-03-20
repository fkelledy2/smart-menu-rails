class AddRoleToEmployees < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :role, :integer
  end
end
