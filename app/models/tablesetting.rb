class Tablesetting < ApplicationRecord
  belongs_to :restaurant
  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  enum tabletype: {
    indoor: 1,
    outdoor: 2
  }

  validates :tabletype, :presence => true
  validates :name, :presence => true
  validates :capacity, :presence => true
  validates :status, :presence => true
  validates :restaurant, :presence => true
end
