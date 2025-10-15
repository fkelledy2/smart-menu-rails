# Minimal employee data for table display - optimized for performance
json.id employee.id
json.name employee.name
json.role employee.role
json.status employee.status
json.sequence employee.sequence
json.url restaurant_employee_url(employee.restaurant, employee, format: :json)
