json.extract! genimage, :id, :image_data, :name, :description, :restaurant_id, :menu_id, :menusection_id, :menuitem_id,
              :created_at, :updated_at
json.url restaurant_genimage_url(genimage.restaurant, genimage, format: :json)
