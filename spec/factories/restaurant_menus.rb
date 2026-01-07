FactoryBot.define do
  factory :restaurant_menu do
    restaurant
    menu
    status { 'active' }
    add_attribute(:sequence) { 1 }
    availability_override_enabled { false }
    availability_state { 'available' }
  end
end
