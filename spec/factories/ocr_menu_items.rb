# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_menu_item do
    association :ocr_menu_section
    name { "Sample Menu Item" }
    description { "A delicious sample item" }
    price { 12.99 }
    sequence(:sequence) { |n| n }
    is_confirmed { false }
    allergens { [] }
    is_vegetarian { false }
    is_vegan { false }
    is_gluten_free { false }
    metadata { {} }
    
    trait :confirmed do
      is_confirmed { true }
    end
    
    trait :vegetarian do
      is_vegetarian { true }
    end
    
    trait :vegan do
      is_vegan { true }
      is_vegetarian { true }
    end
    
    trait :gluten_free do
      is_gluten_free { true }
    end
    
    trait :with_allergens do
      allergens { ["gluten", "dairy"] }
    end
  end
end
