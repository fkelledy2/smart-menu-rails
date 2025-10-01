json.extract! ingredient, :id, :name, :description, :created_at, :updated_at
json.url restaurant_ingredient_url(ingredient.restaurant, ingredient, format: :json)
