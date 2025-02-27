class Menusection < ApplicationRecord
  include ImageUploader::Attachment(:image)
  belongs_to :menu
  has_many :menuitems
  has_one :genimage, dependent: :destroy

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }
  def gen_image_theme
      if( genimage )
          genimage.id
      end
  end

  validates :name, :presence => true
  validates :menu, :presence => true
  validates :status, :presence => true
end
