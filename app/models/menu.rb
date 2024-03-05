class Menu < ApplicationRecord
  belongs_to :restaurant
  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  validates :name, :presence => true
end
