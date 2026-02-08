FactoryBot.define do
  factory :ordr do
    menu

    restaurant { menu.restaurant }
    tablesetting { association :tablesetting, restaurant: restaurant }

    status { :opened }
    nett { 0.0 }
    tip { 0.0 }
    service { 0.0 }
    tax { 0.0 }
    gross { 0.0 }
    covercharge { 0.0 }
    ordercapacity { 0 }
  end
end
