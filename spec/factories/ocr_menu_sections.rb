# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_menu_section do
    ocr_menu_import
    name { 'Appetizers' }
    sequence(:sequence) { |n| n }
    is_confirmed { false }
    metadata { {} }

    trait :confirmed do
      is_confirmed { true }
    end

    trait :with_items do
      after(:create) do |section|
        create_list(:ocr_menu_item, 3, ocr_menu_section: section)
      end
    end
  end
end
