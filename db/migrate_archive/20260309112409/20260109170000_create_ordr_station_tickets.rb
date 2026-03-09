class CreateOrdrStationTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :ordr_station_tickets do |t|
      t.bigint :restaurant_id, null: false
      t.bigint :ordr_id, null: false
      t.integer :station, null: false
      t.integer :status, null: false, default: 20

      t.timestamps
    end

    add_index :ordr_station_tickets, :restaurant_id
    add_index :ordr_station_tickets, :ordr_id
    add_index :ordr_station_tickets, %i[restaurant_id station status], name: 'index_station_tickets_on_restaurant_station_status'
    add_index :ordr_station_tickets, %i[ordr_id station], unique: true

    add_foreign_key :ordr_station_tickets, :restaurants
    add_foreign_key :ordr_station_tickets, :ordrs
  end
end
