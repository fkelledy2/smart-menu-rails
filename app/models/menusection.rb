class Menusection < ApplicationRecord
  include IdentityCache
  
  # Standard ActiveRecord associations
  belongs_to :menu
  has_many :menuitems, dependent: :destroy
  
  # IdentityCache configuration
  cache_index :id
  cache_index :menu_id
  
  # Cache associations
  cache_belongs_to :menu
  cache_has_many :menuitems, embed: :ids
  
  # Responsive image helpers
  def image_url_or_fallback(size = nil)
    if image_attacher.derivatives&.key?(size)
      image_url(size)
    else
      image_url # fallback to original
    end
  end
  def thumb_url
    image_url_or_fallback(:thumb)
  end

  def medium_url
    image_url_or_fallback(:medium)
  end

  def large_url
    image_url_or_fallback(:large)
  end

  def image_srcset
    [
      "#{thumb_url} 200w",
      "#{medium_url} 600w",
      "#{large_url} 1000w"
    ].join(', ')
  end

  def image_sizes
    '(max-width: 600px) 200px, (max-width: 1200px) 600px, 1000px'
  end
  include ImageUploader::Attachment(:image)

  belongs_to :menu
  has_many :menuitems
  has_many :menusectionlocales
  has_one :genimage, dependent: :destroy

  def localised_name(locale)
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

  def localised_description(locale)
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
