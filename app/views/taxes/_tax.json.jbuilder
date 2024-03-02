json.extract! tax, :id, :name, :taxtype, :taxpercentage, :restaurant_id, :created_at, :updated_at
json.url tax_url(tax, format: :json)
