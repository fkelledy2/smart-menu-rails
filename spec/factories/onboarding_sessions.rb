FactoryBot.define do
  factory :onboarding_session do
    user { nil }
    status { 1 }
    wizard_data { 'MyText' }
    restaurant { nil }
    menu { nil }
  end
end
