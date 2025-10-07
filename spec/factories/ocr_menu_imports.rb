# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_menu_import do
    association :restaurant
    name { "Sample Menu Import" }
    status { "pending" }
    processed_pages { 0 }
    total_pages { 1 }
    
    trait :completed do
      status { "completed" }
      processed_pages { 1 }
      completed_at { Time.current }
    end
    
    trait :processing do
      status { "processing" }
    end
    
    trait :failed do
      status { "failed" }
      error_message { "Processing failed" }
      failed_at { Time.current }
    end
  end
end
