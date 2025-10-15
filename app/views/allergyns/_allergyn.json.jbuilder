json.extract! allergyn, :id, :name, :description, :symbol, :status, :sequence, :created_at, :updated_at
json.url restaurant_allergyn_url(allergyn.restaurant_id, allergyn, format: :json)
