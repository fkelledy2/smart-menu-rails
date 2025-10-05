# Handle both ActiveRecord objects (for JSON requests) and hashes (for cached data)
if employee.is_a?(Hash)
  # Handle cached data (hash format)
  json.id employee[:id]
  json.name employee[:name]
  json.role employee[:role]
  json.eid employee[:eid]
  json.status employee[:status]
  json.sequence employee[:sequence]
  json.email employee[:email]
  json.restaurant_id employee[:restaurant_id]
  json.created_at employee[:created_at]
else
  # Handle ActiveRecord object (for JSON requests)
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
end
