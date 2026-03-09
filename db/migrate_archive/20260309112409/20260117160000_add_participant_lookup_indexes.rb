class AddParticipantLookupIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :menuparticipants, :sessionid,
              algorithm: :concurrently,
              if_not_exists: true,
              name: 'index_menuparticipants_on_sessionid'

    add_index :ordrparticipants, %i[ordr_id role sessionid],
              algorithm: :concurrently,
              if_not_exists: true,
              name: 'index_ordrparticipants_on_ordr_role_session'

    add_index :ordrparticipants, %i[ordr_id role employee_id],
              algorithm: :concurrently,
              if_not_exists: true,
              name: 'index_ordrparticipants_on_ordr_role_employee'
  end
end
