  json.id menu.id
  json.name menu.name
  json.description menu.description
  json.image menu.image
  json.status menu.status
  json.sequence menu.sequence
  json.restaurant menu.restaurant
  json.menusections menu.menusections do |menusection|
    json.partial! 'menusections/tmenusection', menusection: menusection
  end
  json.created_at menu.created_at
  json.updated_at menu.updated_at
  json.url menu_url(menu, format: :json)
