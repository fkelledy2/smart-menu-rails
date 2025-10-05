class Menu < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant
  has_many :menusections
  has_many :menuavailabilities
  has_many :menuitems, through: :menusections
  has_many :menulocales
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
  # NOTE: Can't directly cache has_many :through associations with IdentityCache
  # The menuitems will be accessible through the cached menusections
  cache_has_many :menulocales, embed: :ids
  cache_has_one :genimage, embed: :id
  cache_belongs_to :restaurant

  # Cache invalidation hooks
  after_update :invalidate_menu_caches
  after_destroy :invalidate_menu_caches

  def slug
    if Smartmenu.where(restaurant: restaurant, menu: self).first
      Smartmenu.where(restaurant: restaurant, menu: self).first.slug
    else
      ''
    end
  end

  def localised_name(locale)
    mil = Menulocale.where(menu_id: id, locale: locale).first
    rl = Restaurantlocale.where(restaurant_id: restaurant.id, locale: locale).first
    if rl.dfault == true
      name
    elsif mil
      mil.name
    else
      name
    end
  end

  def localised_description(locale)
    mil = Menulocale.where(menu_id: id, locale: locale).first
    rl = Restaurantlocale.where(restaurant_id: restaurant.id, locale: locale).first
    if rl.dfault == true
      description
    elsif mil
      mil.description
    else
      description
    end
  end

  private

  def pdf_menu_scan_format
    return unless pdf_menu_scan.attached?

    unless pdf_menu_scan.content_type.in?(%w[application/pdf])
      errors.add(:pdf_menu_scan, 'must be a PDF file')
    end
  end

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  def gen_image_theme
    genimage&.id
  end

  validates :name, presence: true
  validates :status, presence: true

  private

  def invalidate_menu_caches
    AdvancedCacheService.invalidate_menu_caches(self.id)
    AdvancedCacheService.invalidate_restaurant_caches(self.restaurant_id)
  end
end
