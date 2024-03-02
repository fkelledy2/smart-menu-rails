json.extract! menuitem, :id, :name, :description, :image, :status, :sequence, :calories, :price, :menusection_id, :created_at, :updated_at
json.url menuitem_url(menuitem, format: :json)
