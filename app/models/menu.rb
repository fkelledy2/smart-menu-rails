class Menu < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :restaurant
  belongs_to :owner_restaurant, class_name: 'Restaurant', optional: true
  has_many :restaurant_menus, dependent: :destroy
  has_many :restaurants, through: :restaurant_menus
  has_many :menusections
  has_many :menuavailabilities
  has_many :menuitems, through: :menusections
  # Per-menu allergens via items
  has_many :menuitem_allergyn_mappings, through: :menuitems
  has_many :allergyns, -> { distinct }, through: :menuitem_allergyn_mappings
  has_many :menulocales
  has_one :genimage, dependent: :destroy
  has_many :smartmenus, dependent: :destroy
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

  after_commit :ensure_owner_restaurant_menu, on: :create

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

  def smartmenu
    smartmenus.where(tablesetting_id: nil).first
  end

  def localised_name(locale)
    # Case-insensitive locale lookup
    locale_code = locale.to_s.downcase

    rl = nil
    if restaurant && restaurant.association(:restaurantlocales).loaded?
      rl = restaurant.restaurantlocales.find { |x| x.locale.to_s.downcase == locale_code }
    end
    if rl.nil? && restaurant&.id
      rl = Restaurantlocale.where(restaurant_id: restaurant.id, locale: locale_code).first
      rl ||= Restaurantlocale.where(restaurant_id: restaurant.id).where('LOWER(locale) = ?', locale_code).first
    end

    return name if rl&.dfault == true

    mil = if association(:menulocales).loaded?
            menulocales.find { |x| x.locale.to_s.downcase == locale_code }
          else
            Menulocale.where(menu_id: id, locale: locale_code).first ||
              Menulocale.where(menu_id: id).where('LOWER(locale) = ?', locale_code).first
          end

    mil&.name.presence || name
  end

  def localised_description(locale)
    # Case-insensitive locale lookup
    locale_code = locale.to_s.downcase

    rl = nil
    if restaurant && restaurant.association(:restaurantlocales).loaded?
      rl = restaurant.restaurantlocales.find { |x| x.locale.to_s.downcase == locale_code }
    end
    if rl.nil? && restaurant&.id
      rl = Restaurantlocale.where(restaurant_id: restaurant.id, locale: locale_code).first
      rl ||= Restaurantlocale.where(restaurant_id: restaurant.id).where('LOWER(locale) = ?', locale_code).first
    end

    return description if rl&.dfault == true

    mil = if association(:menulocales).loaded?
            menulocales.find { |x| x.locale.to_s.downcase == locale_code }
          else
            Menulocale.where(menu_id: id, locale: locale_code).first ||
              Menulocale.where(menu_id: id).where('LOWER(locale) = ?', locale_code).first
          end

    mil&.description.presence || description
  end

  private

  def ensure_owner_restaurant_menu
    return if restaurant_id.blank?

    RestaurantMenu.find_or_create_by!(restaurant_id: restaurant_id, menu_id: id) do |rm|
      rm.sequence = RestaurantMenu.where(restaurant_id: restaurant_id).maximum(:sequence).to_i + 1
      rm.status = :active
      rm.availability_override_enabled = false if rm.availability_override_enabled.nil?
      rm.availability_state = :available
    end
  rescue StandardError
    nil
  end

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
