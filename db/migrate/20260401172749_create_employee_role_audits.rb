class CreateEmployeeRoleAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :employee_role_audits do |t|
      t.references :employee,   null: false, foreign_key: true
      t.references :restaurant, null: false, foreign_key: true
      t.references :changed_by, null: false, foreign_key: { to_table: :employees }
      t.integer    :from_role,  null: false
      t.integer    :to_role,    null: false
      t.text       :reason,     null: false

      t.datetime :created_at, null: false
    end

    add_index :employee_role_audits, :created_at
  end
end
