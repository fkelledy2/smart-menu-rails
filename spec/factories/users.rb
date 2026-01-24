FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}-#{SecureRandom.hex(6)}@example.com" }
    password { 'password123' }
    first_name { 'Test' }
    last_name { 'User' }
    plan

    trait :with_restaurant do
      after(:create) do |user|
        create(:restaurant, user: user)
      end
    end
  end
end
