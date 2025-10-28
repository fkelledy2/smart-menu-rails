# Minimal order data for table display - optimized for performance
json.id ordr.id
json.status ordr.status
json.nett ordr.nett
json.service ordr.service
json.tax ordr.tax
json.gross ordr.gross
json.ordrDate ordr.respond_to?(:ordrDate) ? ordr.ordrDate : ordr.created_at.strftime('%Y-%m-%d')

# Only include minimal nested data for table display
if ordr.menu
  json.menu do
    json.id ordr.menu.id
    json.name ordr.menu.name if ordr.menu
  end
end

if ordr.tablesetting
  json.tablesetting do
    json.id ordr.tablesetting.id
    json.name ordr.tablesetting.name if ordr.tablesetting
  end
end

json.url restaurant_ordr_url(ordr.restaurant, ordr, format: :json)
