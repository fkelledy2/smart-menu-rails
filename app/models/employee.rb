class Employee < ApplicationRecord
  belongs_to :restaurant
  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  validates :name, :presence => true
  validates :eid, :presence => true
  validates :status, :presence => true
  validates :restaurant, :presence => true
end
