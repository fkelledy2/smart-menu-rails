  json.id restaurant.id
  json.name restaurant.name
  json.description restaurant.description
  json.address1 restaurant.address1
  json.address2 restaurant.address2
  json.state restaurant.state
  json.city restaurant.city
  json.postcode restaurant.postcode
  json.status restaurant.status
  json.total_capacity restaurant.total_capacity
  json.menus restaurant.menus do |menu|
    json.partial! 'menus/tmenu', menu: menu
  end
  json.employees restaurant.employees do |employee|
    json.partial! 'employees/employee', employee: employee
  end
  json.created_at restaurant.created_at
  json.updated_at restaurant.updated_at
  json.url restaurant_url(restaurant, format: :json)
