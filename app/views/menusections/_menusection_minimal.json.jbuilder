# Minimal menusection data for table display - optimized for performance
json.id menusection.id
json.name menusection.name
json.fromhour menusection.fromhour
json.frommin menusection.frommin
json.tohour menusection.tohour
json.tomin menusection.tomin
json.restricted menusection.restricted
json.status menusection.status
json.sequence menusection.sequence
json.url restaurant_menu_menusection_url(menusection.menu.restaurant, menusection.menu, menusection, format: :json)
