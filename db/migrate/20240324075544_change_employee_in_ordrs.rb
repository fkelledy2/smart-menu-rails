class ChangeEmployeeInOrdrs < ActiveRecord::Migration[7.1]
  def change
    change_column :ordrs, :employee_id, :integer, :null => true
  end
end
