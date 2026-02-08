FactoryBot.define do
  factory :tablesetting do
    restaurant
    sequence(:name) { |n| "Table #{n}" }
    description { 'Test table' }
    status { 'free' }
    tabletype { 'indoor' }
    capacity { 2 }
  end
end
