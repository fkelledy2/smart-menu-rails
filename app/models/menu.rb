class Menu < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include IdentityCache
  
  # Standard ActiveRecord associations
  belongs_to :restaurant
  has_many :menusections, dependent: :destroy
  has_many :menuavailabilities, dependent: :destroy
  has_many :menuitems, through: :menusections
  has_many :menulocales, dependent: :destroy
  has_one :genimage, dependent: :destroy
  has_one_attached :pdf_menu_scan
  
  # Validations
  validate :pdf_menu_scan_format
  
  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  
  # Cache associations
  cache_has_many :menusections, embed: :ids
  cache_has_many :menuavailabilities, embed: :ids
  # Note: Can't directly cache has_many :through associations with IdentityCache
  # The menuitems will be accessible through the cached menusections
  cache_has_many :menulocales, embed: :ids
  cache_has_one :genimage, embed: :id
  cache_belongs_to :restaurant

  def slug
      if Smartmenu.where(restaurant: restaurant, menu: self).first
          Smartmenu.where(restaurant: restaurant, menu: self).first.slug
      else
          ''
      end
  end

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

  private
  def pdf_menu_scan_format
    return unless pdf_menu_scan.attached?
    if !pdf_menu_scan.content_type.in?(%w(application/pdf))
      errors.add(:pdf_menu_scan, 'must be a PDF file')
    end
  end

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

  validates :name, :presence => true
  validates :restaurant, :presence => true
  validates :status, :presence => true
end
