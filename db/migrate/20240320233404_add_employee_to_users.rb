class AddEmployeeToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :employee, null: true, foreign_key: true
  end
end
