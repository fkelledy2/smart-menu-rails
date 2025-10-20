FactoryBot.define do
  factory :menu_edit_session do
    menu { nil }
    user { nil }
    session_id { "MyString" }
    locked_fields { "" }
    started_at { "2025-10-19 22:43:51" }
    last_activity_at { "2025-10-19 22:43:51" }
  end
end
