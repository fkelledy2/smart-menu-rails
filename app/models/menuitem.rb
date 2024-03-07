class Menuitem < ApplicationRecord
  belongs_to :menusection
  has_many :allergyns

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  validates :name, :presence => true
  validates :menusection, :presence => true
  validates :status, :presence => true
  validates :sequence, :presence => true
  validates :price, :presence => true
  validates :calories, :presence => true
end
