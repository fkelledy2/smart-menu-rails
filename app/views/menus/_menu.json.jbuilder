json.id menu.id
json.name menu.name
json.description menu.description
json.image menu.image
json.status menu.status
json.sequence menu.sequence
json.restaurant menu.restaurant.id
json.menusections menu.menusections do |menusection|
  json.partial! 'menusections/menusection', menusection: menusection
end
json.menuavailabilities menu.menuavailabilities do |menuavailability|
  json.partial! 'menuavailabilities/menuavailability', menuavailability: menuavailability
end
json.created_at menu.created_at
json.updated_at menu.updated_at
json.url menu_url(menu, format: :json)
