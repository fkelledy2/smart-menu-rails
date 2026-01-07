class Menu < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant
  belongs_to :owner_restaurant, class_name: 'Restaurant', optional: true
  has_many :restaurant_menus
  has_many :restaurants, through: :restaurant_menus
  has_many :menusections
  has_many :menuavailabilities
  has_many :menuitems, through: :menusections
  # Per-menu allergens via items
  has_many :menuitem_allergyn_mappings, through: :menuitems
  has_many :allergyns, -> { distinct }, through: :menuitem_allergyn_mappings
  has_many :menulocales
  has_one :genimage, dependent: :destroy
  has_one :smartmenu, dependent: :destroy
  has_one_attached :pdf_menu_scan

  # Validations
  validate :pdf_menu_scan_format

  # IdentityCache configuration
  cache_index :id
  cache_index :restaurant_id
  cache_index :owner_restaurant_id

  # Cache associations
  cache_has_many :menusections, embed: :ids
  cache_has_many :menuavailabilities, embed: :ids
  # NOTE: Can't directly cache has_many :through associations with IdentityCache
  # The menuitems will be accessible through the cached menusections
  cache_has_many :menulocales, embed: :ids
  cache_has_one :genimage, embed: :id
  cache_belongs_to :restaurant
  cache_belongs_to :owner_restaurant

  # Cache invalidation hooks
  after_update :invalidate_menu_caches
  after_destroy :invalidate_menu_caches

  # Localization hook - trigger localization after menu is created
  after_commit :enqueue_localization, on: :create

  # Optimized scopes to prevent N+1 queries
  scope :with_availabilities_and_sections, lambda {
    includes(
      :menuavailabilities,
      :restaurant,
      menusections: [
        :menusectionlocales,
        { menuitems: %i[
          menuitemlocales
          allergyns
          sizes
          genimage
        ] },
      ],
    )
  }

  scope :for_customer_display, lambda {
    where(archived: false, status: 'active')
      .with_availabilities_and_sections
  }

  scope :for_management_display, lambda {
    where(archived: false)
      .with_availabilities_and_sections
  }

  def slug
    if Smartmenu.where(restaurant: restaurant, menu: self).first
      Smartmenu.where(restaurant: restaurant, menu: self).first.slug
    else
      ''
    end
  end

  def localised_name(locale)
    # Case-insensitive locale lookup
    mil = Menulocale.where(menu_id: id).where('LOWER(locale) = ?', locale.to_s.downcase).first
    rl = Restaurantlocale.where(restaurant_id: restaurant.id).where('LOWER(locale) = ?', locale.to_s.downcase).first
    if rl&.dfault == true
      name
    elsif mil
      mil.name
    else
      name
    end
  end

  def localised_description(locale)
    # Case-insensitive locale lookup
    mil = Menulocale.where(menu_id: id).where('LOWER(locale) = ?', locale.to_s.downcase).first
    rl = Restaurantlocale.where(restaurant_id: restaurant.id).where('LOWER(locale) = ?', locale.to_s.downcase).first
    if rl&.dfault == true
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

  def invalidate_menu_caches
    AdvancedCacheService.invalidate_menu_caches(id)

    attached_restaurant_ids = restaurant_menus.pluck(:restaurant_id)
    attached_restaurant_ids = [restaurant_id] if attached_restaurant_ids.empty?

    attached_restaurant_ids.uniq.each do |rid|
      AdvancedCacheService.invalidate_restaurant_caches(rid)
    end
  end

  # Enqueue background job to localize this menu to all restaurant locales
  def enqueue_localization
    MenuLocalizationJob.perform_async('menu', id)
  rescue StandardError => e
    Rails.logger.error("[Menu#enqueue_localization] Failed to enqueue localization for menu ##{id}: #{e.message}")
    # Don't raise - localization is not critical to menu creation
  end
end
