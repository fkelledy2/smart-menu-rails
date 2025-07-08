class Menu < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include Localisable

  localisable locale_model: 'Menulocale', locale_foreign_key: :menu_id, parent_chain: ->(menu) { menu }
  belongs_to :restaurant
  has_many :menusections
  has_many :menuavailabilities
  has_many :menuitems, through: :menusections
  has_many :menulocales
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

  def slug
      if Smartmenu.where(restaurant: restaurant, menu: self).first
          Smartmenu.where(restaurant: restaurant, menu: self).first.slug
      else
          ''
      end
  end


  validates :name, :presence => true
  validates :restaurant, :presence => true
  validates :status, :presence => true
end
