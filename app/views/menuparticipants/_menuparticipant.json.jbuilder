json.extract! menuparticipant, :id, :sessionid, :created_at, :updated_at
json.url restaurant_menu_menuparticipant_url(menuparticipant.menu.restaurant, menuparticipant.menu, menuparticipant,
                                             format: :json,)
