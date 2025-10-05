# Now that controllers return proper model instances, we can use clean model serialization
json.id ordr.id
json.status ordr.status
json.orderedAt ordr.orderedAt
json.deliveredAt ordr.deliveredAt
json.paidAt ordr.paidAt
json.nett ordr.nett
json.runningTotal = ordr.runningTotal if ordr.respond_to?(:runningTotal)
json.tip ordr.tip
json.service ordr.service
json.tax ordr.tax
json.gross ordr.gross
json.diners ordr.respond_to?(:diners) ? ordr.diners : nil
json.employee ordr.employee
json.menu ordr.menu
json.tablesetting ordr.tablesetting
json.restaurant ordr.restaurant
json.ordritems ordr.ordritems do |ordritem|
  json.partial! 'ordritems/ordritem', ordritem: ordritem
end
if ordr.respond_to?(:orderedItems)
  json.orderedOrdritems ordr.orderedItems do |ordritem|
    json.partial! 'ordritems/ordritem', ordritem: ordritem
  end
end
if ordr.respond_to?(:preparedItems)
  json.preparedOrdritems ordr.preparedItems do |ordritem|
    json.partial! 'ordritems/ordritem', ordritem: ordritem
  end
end
if ordr.respond_to?(:deliveredItems)
  json.deliveredOrdritems ordr.deliveredItems do |ordritem|
    json.partial! 'ordritems/ordritem', ordritem: ordritem
  end
end
json.ordrparticipants ordr.ordrparticipants do |ordrparticipant|
  json.partial! 'ordrparticipants/ordrparticipant', ordrparticipant: ordrparticipant
end
json.ordrDate ordr.respond_to?(:ordrDate) ? ordr.ordrDate : nil
json.created_at ordr.created_at
json.updated_at ordr.updated_at
json.url restaurant_ordr_url(ordr.restaurant, ordr, format: :json)
