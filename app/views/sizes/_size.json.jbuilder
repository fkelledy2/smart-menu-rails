json.extract! size, :id, :size, :name, :description, :status, :sequence, :created_at, :updated_at
json.url restaurant_size_url(size.restaurant, size, format: :json)
