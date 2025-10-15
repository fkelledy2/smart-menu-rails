# Minimal employees index for table display - optimized for performance
json.array! @employees, partial: 'employees/employee_minimal', as: :employee
