# Minimal tip data for table display - optimized for performance
json.id tip.id
json.name tip.name
json.percentage tip.percentage
json.status tip.status
json.sequence tip.sequence
json.url restaurant_tip_url(tip.restaurant, tip, format: :json)
