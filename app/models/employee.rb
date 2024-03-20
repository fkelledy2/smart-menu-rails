class Employee < ApplicationRecord
  belongs_to :user
  belongs_to :restaurant
  has_many :ordrs, dependent: :destroy

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  enum role: {
    staff: 0,
    manager: 1,
    admin: 2
  }
  validates :name, :presence => true
  validates :eid, :presence => true
  validates :user, :presence => true
  validates :role, :presence => true
  validates :status, :presence => true
  validates :restaurant, :presence => true
end
