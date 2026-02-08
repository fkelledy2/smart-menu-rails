FactoryBot.define do
  factory :smartmenu do
    restaurant
    menu
    tablesetting { nil }
    sequence(:slug) { |n| "smartmenu-slug-#{n}" }
  end
end
