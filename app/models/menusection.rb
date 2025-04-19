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

  def localisedName(locale)
      mil = Menusectionlocale.where(menusection_id: id, locale: locale).first
      rl = Restaurantlocale.where(restaurant_id: self.menu.restaurant.id, locale: locale).first
      if rl.dfault == true
        name
      else
          if mil
              mil.name
          else
              name
          end
      end
  end

  def localisedDescription(locale)
      mil = Menulocale.where(menusection_id: id, locale: locale).first
      rl = Restaurantlocale.where(restaurant_id: self.menu.restaurant.id, locale: locale).first
      if rl.dfault == true
        description
      else
          if mil
              mil.description
          else
              description
          end
      end
  end

  validates :name, :presence => true
  validates :menu, :presence => true
  validates :status, :presence => true
end
