json.extract! ordritemnote, :id, :note, :ordritem_id, :created_at, :updated_at
json.url restaurant_ordritemnote_url(ordritemnote.ordritem.ordr.restaurant, ordritemnote, format: :json)
