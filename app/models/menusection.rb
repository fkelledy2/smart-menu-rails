class Menusection < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include Localisable

  localisable locale_model: 'Menusectionlocale', locale_foreign_key: :menusection_id, parent_chain: ->(section) { section.menu }
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

  def fromOffset
      (fromhour*60)+frommin
  end
  def toOffset
      (tohour*60)+tomin
  end


  validates :name, :presence => true
  validates :menu, :presence => true
  validates :status, :presence => true
end
