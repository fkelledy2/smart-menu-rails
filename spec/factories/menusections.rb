FactoryBot.define do
  factory :menusection do
    association :menu
    sequence(:name) { |n| "Section #{n}" }
    description { 'Section description' }
    status { 'active' }

    # Defaults for tasting disabled
    tasting_menu { false }
    price_per { 'person' }
    tasting_price_cents { nil }
    tasting_currency { nil }
    allow_pairing { false }
    pairing_price_cents { nil }
    pairing_currency { nil }

    trait :tasting do
      tasting_menu { true }
      price_per { 'person' }
      tasting_price_cents { 5000 }
      tasting_currency { menu.restaurant.currency.presence || 'USD' }
    end

    trait :with_pairing do
      allow_pairing { true }
      pairing_price_cents { 2500 }
      pairing_currency { menu.restaurant.currency.presence || 'USD' }
    end
  end
end
