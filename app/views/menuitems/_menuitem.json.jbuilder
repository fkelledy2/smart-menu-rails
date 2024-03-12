  json.id menuitem.id
  json.name menuitem.name
  json.description menuitem.description
  json.image menuitem.image
  json.status menuitem.status
  json.sequence menuitem.sequence
  json.calories menuitem.calories
  json.price menuitem.price
  json.menusection menuitem.menusection
  json.allergyns menuitem.allergyns do |allergyn|
    json.partial! 'allergyns/tallergyn', allergyn: allergyn
  end
  json.tags menuitem.tags do |tag|
    json.partial! 'tags/ttag', tag: tag
  end
  json.created_at menuitem.created_at
  json.updated_at menuitem.updated_at
  json.url menuitem_url(menuitem, format: :json)
