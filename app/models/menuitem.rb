class Menuitem < ApplicationRecord
  include ImageUploader::Attachment(:image)

  has_many :menuitemlocales

  belongs_to :menusection

  def localised_name(locale)
      mil = Menuitemlocale.where(menuitem_id: id, locale: locale).first
      rl = Restaurantlocale.where(restaurant_id: self.menusection.menu.restaurant.id, locale: locale).first
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
      mil = Menuitemlocale.where(menuitem_id: id, locale: locale).first
      rl = Restaurantlocale.where(restaurant_id: self.menusection.menu.restaurant.id, locale: locale).first
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

  has_many :menuitem_allergyn_mappings, dependent: :destroy
  has_many :allergyns, through: :menuitem_allergyn_mappings

  has_many :menuitem_tag_mappings, dependent: :destroy
  has_many :tags, through: :menuitem_tag_mappings

  has_many :menuitem_size_mappings, dependent: :destroy
  has_many :sizes, through: :menuitem_size_mappings

  has_many :menuitem_ingredient_mappings, dependent: :destroy
  has_many :ingredients, through: :menuitem_ingredient_mappings

  has_one :inventory, dependent: :destroy
  has_one :genimage, dependent: :destroy

  enum status: {
    inactive: 0,
    active: 1,
    archived: 2
  }

  enum itemtype: {
    food: 0,
    beverage: 1,
    wine: 2
  }

  def genImageId
      if( genimage )
          genimage.id
      else
        -1
      end
  end


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

  # Returns a srcset string for responsive images
  def image_srcset
    [
      "#{thumb_url} 200w",
      "#{medium_url} 600w",
      "#{large_url} 1000w"
    ].join(', ')
  end

  # Returns a default sizes attribute for responsive images
  def image_sizes
    '(max-width: 600px) 200px, (max-width: 1200px) 600px, 1000px'
  end

  validates :inventory, :presence => false
  validates :name, :presence => true
  validates :menusection, :presence => true
  validates :itemtype, :presence => true
  validates :status, :presence => true
  validates :preptime, :presence => true, :numericality => {:only_integer => true}
  validates :price, :presence => true, :numericality => {:only_float => true}
  validates :calories, :presence => true, :numericality => {:only_integer => true}
end
