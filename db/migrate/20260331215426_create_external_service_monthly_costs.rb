class CreateExternalServiceMonthlyCosts < ActiveRecord::Migration[7.2]
  def change
    create_table :external_service_monthly_costs do |t|
      t.date :month, null: false
      t.string :service, null: false
      t.string :currency, null: false, default: 'EUR'
      t.integer :amount_cents, null: false, default: 0
      t.string :source, null: false, default: 'manual'
      t.text :notes
      t.jsonb :evidence, null: false, default: {}
      t.bigint :created_by_user_id

      t.timestamps
    end

    add_index :external_service_monthly_costs,
              %i[month service currency],
              unique: true,
              name: 'index_ext_svc_monthly_costs_unique'
    add_index :external_service_monthly_costs, :month
    add_index :external_service_monthly_costs, :service
  end
end
