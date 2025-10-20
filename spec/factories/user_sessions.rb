FactoryBot.define do
  factory :user_session do
    user { nil }
    session_id { "MyString" }
    resource_type { "MyString" }
    resource_id { "" }
    status { "MyString" }
    last_activity_at { "2025-10-19 22:43:41" }
    metadata { "" }
  end
end
