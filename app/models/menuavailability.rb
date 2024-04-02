class Menuavailability < ApplicationRecord
  belongs_to :menu

  enum dayofweek: {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  enum status: {
    open: 0,
    closed: 1
  }
end
