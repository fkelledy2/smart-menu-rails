class AddEmailToEmployees < ActiveRecord::Migration[7.1]
  def change
    add_column :employees, :email, :string
  end
end
