class Menu < ApplicationRecord
  belongs_to :restaurant
  has_many :menusections

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  validates :name, :presence => true
  validates :restaurant, :presence => true
  validates :status, :presence => true
  validates :sequence, :presence => true
end
