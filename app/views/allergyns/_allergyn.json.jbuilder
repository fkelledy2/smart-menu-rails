json.id allergyn.id
json.name allergyn.name
json.description allergyn.description
json.symbol allergyn.symbol
json.restaurant allergyn.restaurant.id
json.sequence allergyn.sequence
json.status allergyn.status
json.created_at allergyn.created_at
json.updated_at allergyn.updated_at
json.url restaurant_allergyn_url(allergyn.restaurant, allergyn, format: :json)
json.data do
  json.id allergyn.id
  json.name allergyn.name
  json.description allergyn.description
  json.symbol allergyn.symbol
  json.status allergyn.status
  json.sequence allergyn.sequence
end
