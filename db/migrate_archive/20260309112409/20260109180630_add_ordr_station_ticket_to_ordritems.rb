class AddOrdrStationTicketToOrdritems < ActiveRecord::Migration[7.2]
  def up
    add_column :ordritems, :ordr_station_ticket_id, :bigint
    add_index :ordritems, :ordr_station_ticket_id
    add_foreign_key :ordritems, :ordr_station_tickets

    execute <<~SQL
      UPDATE ordritems
      SET ordr_station_ticket_id = tickets.id
      FROM ordr_station_tickets tickets, menuitems
      WHERE ordritems.ordr_id = tickets.ordr_id
        AND menuitems.id = ordritems.menuitem_id
        AND ordritems.ordr_station_ticket_id IS NULL
        AND ordritems.status IN (20, 22, 24)
        AND (
          (tickets.station = 0 AND menuitems.itemtype = 0) OR
          (tickets.station = 1 AND menuitems.itemtype IN (1, 2))
        )
    SQL

    execute <<~SQL
      UPDATE ordr_station_tickets
      SET submitted_at = COALESCE(submitted_at, created_at)
      WHERE submitted_at IS NULL
    SQL
  end

  def down
    remove_foreign_key :ordritems, :ordr_station_tickets
    remove_index :ordritems, :ordr_station_ticket_id
    remove_column :ordritems, :ordr_station_ticket_id
  end
end
