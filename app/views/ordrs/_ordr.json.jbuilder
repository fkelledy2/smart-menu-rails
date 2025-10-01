json.id ordr.id
json.status ordr.status
json.orderedAt ordr.orderedAt
json.deliveredAt ordr.deliveredAt
json.paidAt ordr.paidAt
json.nett ordr.nett
json.runningTotal = ordr.runningTotal
json.tip ordr.tip
json.service ordr.service
json.tax ordr.tax
json.gross ordr.gross
json.diners ordr.diners
json.employee ordr.employee
json.menu ordr.menu
json.tablesetting ordr.tablesetting
json.restaurant ordr.restaurant
json.ordritems ordr.ordritems do |ordritem|
  json.partial! 'ordritems/ordritem', ordritem: ordritem
end
json.orderedOrdritems ordr.orderedItems do |ordritem|
  json.partial! 'ordritems/ordritem', ordritem: ordritem
end
json.preparedOrdritems ordr.preparedItems do |ordritem|
  json.partial! 'ordritems/ordritem', ordritem: ordritem
end
json.deliveredOrdritems ordr.deliveredItems do |ordritem|
  json.partial! 'ordritems/ordritem', ordritem: ordritem
end
json.ordrparticipants ordr.ordrparticipants do |ordrparticipant|
  json.partial! 'ordrparticipants/ordrparticipant', ordrparticipant: ordrparticipant
end
json.ordrDate ordr.ordrDate
json.created_at ordr.created_at
json.updated_at ordr.updated_at
json.url restaurant_ordr_url(ordr.restaurant, ordr, format: :json)
