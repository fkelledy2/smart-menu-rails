FactoryBot.define do
  factory :push_subscription do
    user { nil }
    endpoint { 'MyString' }
    p256dh_key { 'MyText' }
    auth_key { 'MyText' }
    active { false }
  end
end
