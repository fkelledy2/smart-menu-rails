json.extract! ordr, :id, :orderedAt, :deliveredAt, :paidAt, :nett, :tip, :service, :tax, :gross, :employee_id, :tablesetting_id, :menu_id, :restaurant_id, :created_at, :updated_at
json.url ordr_url(ordr, format: :json)
