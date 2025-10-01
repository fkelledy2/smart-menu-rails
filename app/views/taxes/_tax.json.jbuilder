json.id tax.id
json.name tax.name
json.taxtype tax.taxtype
json.taxpercentage tax.taxpercentage
json.restaurant tax.restaurant.id
json.sequence tax.sequence
json.status tax.status
json.created_at tax.created_at
json.updated_at tax.updated_at
json.url restaurant_tax_url(tax.restaurant, tax, format: :json)
