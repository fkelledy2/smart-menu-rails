FactoryBot.define do
  factory :ordrparticipant do
    ordr

    role { :customer }
    sequence(:sessionid) { |n| "session-#{n}" }
  end
end
