FactoryBot.define do
  factory :menuitem do
    association :menusection
    sequence(:name) { |n| "Item #{n}" }
    description { 'Test item' }
    status { 'active' }
    itemtype { 'food' }
    preptime { 0 }
    price { 0.0 }
    calories { 0 }

    hidden { false }
    tasting_carrier { false }

    trait :carrier do
      tasting_carrier { true }
      hidden { true }
    end
  end
end
