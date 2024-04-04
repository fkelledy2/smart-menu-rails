json.extract! ordrparticipant, :id, :sessionid, :action, :role, :employee_id, :ordr_id, :ordritem_id, :name, :created_at, :updated_at
json.url ordrparticipant_url(ordrparticipant, format: :json)
