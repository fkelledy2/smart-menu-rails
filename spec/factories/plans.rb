FactoryBot.define do
  factory :plan do
    key { 'plan.starter.key' }
    descriptionKey { 'Starter Plan' }
    status { 'active' }
    pricePerMonth { 9.99 }
    pricePerYear { 99.99 }
    locations { 1 }
    menusperlocation { 5 }
    itemspermenu { 100 }
    languages { 1 }
    favourite { false }
    action { 'register' }
    attribute1 { 'Feature 1' }
    attribute2 { 'Feature 2' }
    attribute3 { 'Feature 3' }
    attribute4 { 'Feature 4' }
    attribute5 { 'Feature 5' }
    attribut6 { 'Feature 6' }
  end
end
