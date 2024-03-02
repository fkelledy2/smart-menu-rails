json.extract! employee, :id, :name, :eid, :image, :status, :restaurant_id, :created_at, :updated_at
json.url employee_url(employee, format: :json)
