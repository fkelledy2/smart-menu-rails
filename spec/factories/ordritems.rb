FactoryBot.define do
  factory :ordritem do
    ordr
    menuitem

    ordritemprice { 10.0 }
    status { :opened }
    quantity { 1 }
  end
end
