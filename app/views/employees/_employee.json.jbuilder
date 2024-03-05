json.extract! employee, :id, :name, :eid, :image, :status, :restaurant_id, :restaurant, :created_at, :updated_at
json.url employee_url(employee, format: :json)
