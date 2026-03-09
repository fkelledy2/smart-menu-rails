# frozen_string_literal: true

class AddSmartmenuPerformanceIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    # CRITICAL: The open-order lookup in SmartmenusController#load_open_order_and_participant
    # filters on (menu_id, tablesetting_id, status) but only single-column indexes exist.
    # This composite index covers the exact WHERE clause and avoids sequential scans.
    add_index :ordrs, [:menu_id, :tablesetting_id, :status],
              name: "index_ordrs_on_menu_table_status",
              algorithm: :concurrently,
              if_not_exists: true

    # Menuparticipant lookup: find_or_create_by(sessionid:) then checks smartmenu_id.
    # A composite unique index prevents duplicates and speeds up the lookup.
    add_index :menuparticipants, [:sessionid, :smartmenu_id],
              name: "index_menuparticipants_on_session_smartmenu",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true

    # AlcoholOrderEvent.exists?(ordr_id:, age_check_acknowledged: false) on every show.
    # Composite index avoids scanning all events for the order.
    add_index :alcohol_order_events, [:ordr_id, :age_check_acknowledged],
              name: "index_alcohol_events_on_ordr_ack",
              algorithm: :concurrently,
              if_not_exists: true

    # Ordrparticipant lookup for customer participants:
    # find_or_create_by!(ordr:, role:, sessionid:)
    # The existing index covers (ordr_id, role, sessionid) ✓ — no change needed.

    # Ordraction find_or_create_by!(ordrparticipant:, ordr:, ordritem: nil, action:)
    add_index :ordractions, [:ordrparticipant_id, :ordr_id, :action],
              name: "index_ordractions_on_participant_ordr_action",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
