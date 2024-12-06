class Restaurant < ApplicationRecord
  include ImageUploader::Attachment(:image)
  belongs_to :user
  has_many :tablesettings, dependent: :delete_all
  has_many :menus, dependent: :delete_all
  has_many :employees, dependent: :delete_all
  has_many :taxes, dependent: :delete_all
  has_many :tips, dependent: :delete_all
  has_many :restaurantavailabilities, dependent: :delete_all
  has_many :menusections, through: :menus
  has_many :menuavailabilities, through: :menus
  has_one :genimage, dependent: :destroy

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  def total_capacity
    tablesettings.map(&:capacity).sum
  end

  validates :name, :presence => true
  validates :address1, :presence => false
  validates :city, :presence => false
  validates :postcode, :presence => false
  validates :country, :presence => false
  validates :status, :presence => true
  validates :user, :presence => true
end
