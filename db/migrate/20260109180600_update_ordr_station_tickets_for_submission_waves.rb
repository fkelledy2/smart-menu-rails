class UpdateOrdrStationTicketsForSubmissionWaves < ActiveRecord::Migration[7.2]
  def change
    remove_index :ordr_station_tickets, column: %i[ordr_id station]

    add_column :ordr_station_tickets, :sequence, :integer, null: false, default: 1
    add_column :ordr_station_tickets, :submitted_at, :datetime

    add_index :ordr_station_tickets, %i[ordr_id station sequence], unique: true, name: 'index_station_tickets_on_order_station_sequence'
  end
end
