FactoryBot.define do
  factory :ordrparticipant do
    association :ordr

    role { :customer }
    sequence(:sessionid) { |n| "session-#{n}" }
  end
end
