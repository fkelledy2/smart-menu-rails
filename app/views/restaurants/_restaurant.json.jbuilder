json.extract! restaurant, :id, :name, :description, :address1, :address2, :state, :city, :postcode, :country, :image, :status, :capacity, :user_id, :user.name, :created_at, :updated_at
json.url restaurant_url(restaurant, format: :json)
