FactoryBot.define do
  factory :ordritem do
    association :ordr
    association :menuitem

    ordritemprice { 10.0 }
    status { :opened }
  end
end
