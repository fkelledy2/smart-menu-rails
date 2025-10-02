json.extract! menuparticipant, :id, :sessionid, :created_at, :updated_at
json.url menu_menuparticipant_url(menuparticipant.menu, menuparticipant, format: :json)
