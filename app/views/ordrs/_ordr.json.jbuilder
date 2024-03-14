  json.id ordr.id
  json.orderedAt ordr.orderedAt
  json.deliveredAt ordr.deliveredAt
  json.paidAt ordr.paidAt
  json.nett ordr.nett
  json.tip ordr.tip
  json.service ordr.service
  json.tax ordr.tax
  json.gross ordr.gross
  json.employee ordr.employee
  json.menu ordr.menu
  json.tablesetting ordr.tablesetting
  json.restaurant ordr.restaurant
  json.ordritems ordr.ordritems do |ordritem|
    json.partial! 'ordritems/ordritem', ordritem: ordritem
  end
  json.created_at ordr.created_at
  json.updated_at ordr.updated_at
  json.url ordr_url(ordr, format: :json)
