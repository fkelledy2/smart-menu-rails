FactoryBot.define do
  factory :employee do
    sequence(:name) { |n| "Employee #{n}" }
    sequence(:eid) { |n| "E#{n}" }
    role { 'admin' }
    status { 'active' }
    user
    restaurant
  end
end
