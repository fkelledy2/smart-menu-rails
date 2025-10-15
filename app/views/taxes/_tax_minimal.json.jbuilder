# Minimal tax data for table display - optimized for performance
json.id tax.id
json.name tax.name
json.percentage tax.percentage
json.status tax.status
json.sequence tax.sequence
json.url restaurant_tax_url(tax.restaurant, tax, format: :json)
