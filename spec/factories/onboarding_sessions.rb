FactoryBot.define do
  factory :onboarding_session do
    user { nil }
    status { 'started' }
    wizard_data { {} }
    restaurant { nil }
    menu { nil }
  end
end
