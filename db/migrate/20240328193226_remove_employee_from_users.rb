class RemoveEmployeeFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :employee_id
  end
end
