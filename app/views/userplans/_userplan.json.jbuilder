json.extract! userplan, :id, :user_id, :plan_id, :created_at, :updated_at
json.url userplan_url(userplan, format: :json)
