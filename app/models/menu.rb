class Menu < ApplicationRecord
  include ImageUploader::Attachment(:image)

  belongs_to :restaurant
  has_many :menusections
  has_many :menuavailabilities
  has_many :menuitems, through: :menusections
  has_many :menulocales
  has_one :genimage, dependent: :destroy

  def localised_name(locale)
      mil = Menulocale.where(menu_id: id, locale: locale).first
      rl = Restaurantlocale.where(restaurant_id: self.restaurant.id, locale: locale).first
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

  def localised_description(locale)
      mil = Menulocale.where(menu_id: id, locale: locale).first
      rl = Restaurantlocale.where(restaurant_id: self.restaurant.id, locale: locale).first
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
