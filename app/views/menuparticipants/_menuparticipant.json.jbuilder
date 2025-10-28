json.extract! menuparticipant, :id, :sessionid, :created_at, :updated_at
if menuparticipant.smartmenu&.menu && menuparticipant.smartmenu.restaurant
  json.url restaurant_menu_menuparticipant_url(menuparticipant.smartmenu.restaurant, menuparticipant.smartmenu.menu,
                                               menuparticipant, format: :json,)
end
