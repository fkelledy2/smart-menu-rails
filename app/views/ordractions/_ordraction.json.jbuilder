json.extract! ordraction, :id, :action, :employee_id, :ordrparticipant_id, :ordr_id, :ordritem_id, :created_at,
              :updated_at
json.url restaurant_ordraction_url(ordraction.ordr.restaurant, ordraction, format: :json)
