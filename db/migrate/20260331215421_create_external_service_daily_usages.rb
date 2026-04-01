class CreateExternalServiceDailyUsages < ActiveRecord::Migration[7.2]
  def change
    create_table :external_service_daily_usages do |t|
      t.date :date, null: false
      t.string :service, null: false
      t.string :dimension, null: false
      t.decimal :units, precision: 15, scale: 4, null: false, default: 0
      t.string :unit_type, null: false, default: 'count'
      t.bigint :restaurant_id
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :external_service_daily_usages,
              %i[date service dimension restaurant_id],
              unique: true,
              name: 'index_ext_svc_daily_usages_unique'
    add_index :external_service_daily_usages, :service
    add_index :external_service_daily_usages, :date
    add_index :external_service_daily_usages, :restaurant_id
  end
end
