# Minimal menu data for table display - optimized for performance
json.id menu.id
json.name menu.name
json.status menu.status
json.sequence menu.sequence
json.restaurant do
  json.id @restaurant.id
  json.name @restaurant.name
end
json.url restaurant_menu_url(@restaurant, menu, format: :json)
