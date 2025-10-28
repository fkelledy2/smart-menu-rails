json.extract! hero_image, :id, :image_url, :alt_text, :sequence, :status, :source_url, :created_at, :updated_at
json.url hero_image_url(hero_image, format: :json)
