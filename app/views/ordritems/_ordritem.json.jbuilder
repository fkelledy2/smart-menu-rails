json.id ordritem.id
json.ordr ordritem.ordr
json.menuitem ordritem.menuitem
json.created_at ordritem.created_at
json.updated_at ordritem.updated_at
json.url restaurant_ordritem_url(ordritem.ordr.restaurant, ordritem, format: :json)
