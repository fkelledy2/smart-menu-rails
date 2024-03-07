json.extract! restaurant, :id, :name, :description, :address1, :address2, :state, :city, :postcode, :country, :image, :status, :capacity, :total_capacity, :user_id, :user, :employees, :tablesettings, :taxes, :created_at, :updated_at
json.url restaurant_url(restaurant, format: :json)
