FactoryBot.define do
  factory :restaurant do
    sequence(:name) { |n| "Restaurant #{n}" }
    address1 { '123 Main St' }
    city { 'Test City' }
    country { 'US' }
    status { 'active' }
    user
  end
end
