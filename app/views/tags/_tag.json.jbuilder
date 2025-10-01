json.extract! tag, :id, :name, :description, :created_at, :updated_at
json.url restaurant_tag_url(tag.restaurant, tag, format: :json)
