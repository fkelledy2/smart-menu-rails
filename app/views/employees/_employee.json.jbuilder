json.id employee.id
json.name employee.name
json.role employee.role
json.user employee.user
json.eid employee.eid
json.image employee.image
json.status employee.status
json.sequence employee.sequence
json.restaurant employee.restaurant.id
json.created_at employee.created_at
json.updated_at employee.updated_at
json.url restaurant_employee_url(employee.restaurant, employee, format: :json)
