class Restaurant < ApplicationRecord
  belongs_to :user
  has_many :tablesettings, dependent: :delete_all
  has_many :menus, dependent: :delete_all
  has_many :employees, dependent: :delete_all
  has_many :taxes, dependent: :delete_all

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
