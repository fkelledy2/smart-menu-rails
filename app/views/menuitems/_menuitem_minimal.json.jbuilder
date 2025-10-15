# Minimal menuitem data for table display - optimized for performance
json.id menuitem.id
json.genImageId menuitem.genimage&.id
json.name menuitem.name
json.calories menuitem.calories
json.price menuitem.price
json.preptime menuitem.preptime
json.status menuitem.status
json.sequence menuitem.sequence
json.inventory menuitem.inventory
if menuitem.menusection&.menu&.restaurant
  json.url restaurant_menu_menusection_menuitem_url(menuitem.menusection.menu.restaurant, menuitem.menusection.menu, menuitem.menusection, menuitem, format: :json)
else
  json.url nil
end
