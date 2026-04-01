class AddFulfillmentTrackingToOrdritems < ActiveRecord::Migration[7.2]
  def change
    add_column :ordritems, :fulfillment_status, :integer, null: false, default: 0
    add_column :ordritems, :station, :integer
    add_column :ordritems, :fulfillment_status_changed_at, :datetime
    add_column :ordritems, :preparing_at, :datetime
    add_column :ordritems, :ready_at, :datetime
    add_column :ordritems, :collected_at, :datetime

    add_index :ordritems, %i[ordr_id fulfillment_status],
              name: 'index_ordritems_on_ordr_fulfillment_status'
    add_index :ordritems, %i[ordr_id station fulfillment_status],
              name: 'index_ordritems_on_ordr_station_fulfillment'
  end
end
