class Restaurant < ApplicationRecord
  belongs_to :user
  has_many :tablesettings
  has_many :menus
  has_many :employees
  has_many :taxes

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  def total_capacity
    tablesettings.map(&:capacity).sum
  end

  validates :name, :presence => true
  validates :address1, :presence => true
  validates :city, :presence => true
  validates :postcode, :presence => true
  validates :country, :presence => true
  validates :status, :presence => true
  validates :user, :presence => true
end
