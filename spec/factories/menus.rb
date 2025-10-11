FactoryBot.define do
  factory :menu do
    sequence(:name) { |n| "Menu #{n}" }
    description { 'Test menu description' }
    status { 'active' }
    restaurant
  end
end
