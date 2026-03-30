class FixEmployeeFkOnOrdrparticipants < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :ordrparticipants, :employees
    add_foreign_key :ordrparticipants, :employees, column: :employee_id, on_delete: :nullify
  end
end
