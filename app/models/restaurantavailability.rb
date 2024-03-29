class Restaurantavailability < ApplicationRecord
  belongs_to :restaurant

  enum dayofweek: {
    monday: 0,
    tuesday: 1,
    wednesday: 2,
    thursday: 3,
    friday: 4,
    saturday: 5,
    sunday: 6
  }

  enum status: {
    open: 0,
    closed: 1
  }
end
