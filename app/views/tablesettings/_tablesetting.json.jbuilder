json.id tablesetting.id
json.name tablesetting.name
json.description tablesetting.description
json.sequence tablesetting.sequence
json.status tablesetting.status
json.tabletype tablesetting.tabletype
json.capacity tablesetting.capacity
json.restaurant tablesetting.restaurant.id
json.created_at tablesetting.created_at
json.updated_at tablesetting.updated_at
json.url restaurant_tablesetting_url(tablesetting.restaurant, tablesetting, format: :json)
