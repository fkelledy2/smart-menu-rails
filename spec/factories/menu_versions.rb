FactoryBot.define do
  factory :menu_version do
    menu
    sequence(:version_number) { |n| n }
    snapshot_json { { schema_version: 1, menu: {}, menuavailabilities: [], menusections: [] } }
    is_active { false }
    starts_at { nil }
    ends_at { nil }
    created_by_user { nil }
  end
end
