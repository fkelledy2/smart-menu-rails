FactoryBot.define do
  factory :resource_lock do
    resource_type { "MyString" }
    resource_id { "" }
    field_name { "MyString" }
    user { nil }
    session_id { "MyString" }
    acquired_at { "2025-10-19 22:44:00" }
    expires_at { "2025-10-19 22:44:00" }
  end
end
