class Menusection < ApplicationRecord
  include ImageUploader::Attachment(:image)
  belongs_to :menu
  has_many :menuitems

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  validates :name, :presence => true
  validates :menu, :presence => true
  validates :status, :presence => true
  validates :sequence, :presence => true
end
