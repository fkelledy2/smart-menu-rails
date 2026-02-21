class Restaurant < ApplicationRecord
  has_one :alcohol_policy, dependent: :destroy
  include ImageUploader::Attachment(:image)
  include IdentityCache
  include L2Cacheable

  # Standard ActiveRecord associations
  belongs_to :user

  has_many :tablesettings, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all, counter_cache: :tablesettings_count
  has_many :menus, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all, counter_cache: :menus_count
  has_many :restaurant_menus, dependent: :delete_all
  has_many :shared_menus, through: :restaurant_menus, source: :menu
  has_many :employees, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all, counter_cache: :employees_count

  def alcohol_allowed_now?(now: Time.zone.now)
    return false if respond_to?(:allow_alcohol) && !allow_alcohol
    return true unless alcohol_policy

    alcohol_policy.allowed_now?(now: now)
  end

  has_many :smartmenus, dependent: :delete_all
  has_many :ordrs, -> { reorder(orderedAt: :desc, id: :desc) }, dependent: :delete_all, counter_cache: :ordrs_count
  has_many :ordr_station_tickets, dependent: :delete_all
  has_many :taxes, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all
  has_many :tips, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all

  has_one :payment_profile, dependent: :destroy
  has_many :provider_accounts, dependent: :delete_all
  has_many :payment_attempts, dependent: :delete_all
  has_many :payment_refunds, dependent: :delete_all
  has_one :restaurant_subscription, dependent: :destroy
  has_many :restaurantavailabilities, dependent: :delete_all
  has_many :menusections, through: :menus
  has_many :menuavailabilities, through: :menus
  has_one  :genimage, dependent: :destroy
  has_many :tracks, dependent: :delete_all
  has_many :restaurantlocales, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all
  has_many :allergyns, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all
  has_many :sizes, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all
  has_many :ocr_menu_imports, -> { reorder(created_at: :desc, id: :desc) }, dependent: :destroy, counter_cache: :ocr_menu_imports_count
  has_one :discovered_restaurant
  has_many :restaurant_removal_requests, dependent: :destroy
  has_many :restaurant_claim_requests, dependent: :destroy

  # IdentityCache configuration
  cache_index :id
  cache_index :user_id

  # Cache associations - must be defined after the actual associations
  cache_has_many :menus, embed: :ids
  cache_has_many :tablesettings, embed: :ids
  cache_has_many :employees, embed: :ids
  cache_has_many :ordrs, embed: :ids
  cache_has_many :taxes, embed: :ids
  cache_has_many :ocr_menu_imports, embed: :ids
  cache_has_many :tips, embed: :ids
  cache_has_many :restaurantavailabilities, embed: :ids
  cache_has_many :restaurantlocales, embed: :ids
  cache_has_many :allergyns, embed: :ids
  cache_has_many :sizes, embed: :ids
  cache_has_one :genimage, embed: :id

  # Cache invalidation hooks - DISABLED in favor of background jobs for performance
  # after_update :invalidate_restaurant_caches
  # after_destroy :invalidate_restaurant_caches

  # Returns all locale codes for this restaurant
  def locales
    restaurantlocales.pluck(:locale)
  end

  def publish_allowed?
    user&.super_admin? || restaurant_subscription&.active_or_trialing_with_payment_method?
  end

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  enum :wifiEncryptionType, {
    WPA: 0,
    WEP: 1,
    NONE: 2,
  }

  enum :claim_status, {
    unclaimed: 0,
    soft_claimed: 1,
    claimed: 2,
    verified: 3,
  }

  enum :provisioned_by, {
    provisioned_by_owner: 0,
    provisioned_by_system: 1,
  }, prefix: :provisioned

  def spotifyAuthUrl
    "/auth/spotify?restaurant_id=#{id}"
  end

  def spotifyPlaylistUrl
    "/restaurants/#{id}/tracks"
  end

  def preview_published?
    preview_enabled? && preview_published_at.present?
  end

  def whiskey_bar?
    Array(establishment_types).include?('whiskey_bar')
  end

  def whiskey_ambassador_ready?
    return false unless whiskey_ambassador_enabled?

    menus.any? do |menu|
      menu.menuitems
          .where(sommelier_category: 'whiskey', status: 'active')
          .where("sommelier_parsed_fields->>'whiskey_region' IS NOT NULL OR sommelier_parsed_fields->>'staff_flavor_cluster' IS NOT NULL")
          .count >= 10
    end
  end

  def gen_image_theme
    genimage&.id
  end

  def total_capacity
    tablesettings.sum(&:capacity)
  end

  def wifiQRString
    wifiQRString = 'WIFI:S:'
    if wifissid
      wifiQRString.concat("#{wifissid};")
    end
    if wifiEncryptionType
      wifiQRString.concat("T:#{wifiEncryptionType};")
    end
    if wifiPassword
      wifiQRString.concat("P:#{wifiPassword};")
    end
    if wifiHidden
      wifiQRString.concat('H:true;')
    else
      wifiQRString.concat('H:false;')
    end
  end

  def defaultLocale
    if association(:restaurantlocales).loaded?
      restaurantlocales.find { |rl| rl.status.to_s == 'active' && rl.dfault == true }
    else
      Restaurantlocale.find_by(restaurant_id: id, status: 'active', dfault: true)
    end
  end

  def getLocale(locale)
    requested = locale.to_s.downcase
    if association(:restaurantlocales).loaded?
      restaurantlocales.find { |rl| rl.status.to_s == 'active' && rl.locale.to_s.downcase == requested }
    else
      # Case-insensitive lookup to handle both 'it' and 'IT'
      Restaurantlocale.find_by(restaurant_id: id, status: 'active')
        &.then { |rl| rl&.locale&.downcase == requested ? rl : nil } ||
        Restaurantlocale.where(restaurant_id: id, status: 'active')
          .where('LOWER(locale) = ?', requested)
          .first
    end
  end

  validates :name, presence: true
  validates :address1, presence: false
  validates :city, presence: false
  validates :postcode, presence: false
  validates :country, presence: false
  validates :status, presence: true

  # Onboarding guidance helpers
  def onboarding_missing_details_fields
    missing = []
    missing << :description if description.blank?
    missing << :currency if currency.blank?

    address_ok = address1.present? || city.present? || postcode.present?
    missing << :address unless address_ok
    missing << :country if country.blank?

    missing
  end

  def onboarding_next_section
    # 1) Details: require description, currency, and address + country (for correct tax inference)
    address_ok = address1.present? || city.present? || postcode.present?
    details_ok = description.present? && currency.present? && address_ok && country.present?
    return 'details' unless details_ok

    # 2) Localization: require at least one language and a default language set
    has_locales = restaurantlocales.any?
    has_default_locale = restaurantlocales.exists?(status: 'active', dfault: true)
    return 'localization' unless has_locales && has_default_locale

    # 3) Tables: require at least one table setting
    return 'tables' unless tablesettings.exists?(archived: false)

    # 4) Staff: require at least one employee
    return 'staff' unless employees.any?

    # 5) Menus: require at least one menu
    has_any_menu = restaurant_menus
      .where.not(status: RestaurantMenu.statuses[:archived])
      .joins(:menu)
      .exists?(menus: { archived: false })
    return 'menus' unless has_any_menu

    nil
  end

  def onboarding_incomplete?
    onboarding_next_section.present?
  end

  # Returns true if any required onboarding setup is missing for enabling Quick Actions
  def onboarding_quick_actions_blocked?
    return true if name.blank?
    return true if description.blank?
    return true if currency.blank?

    address_ok = address1.present? || city.present? || postcode.present?
    return true unless address_ok
    return true if country.blank?
    # Context and image style profile
    return true if respond_to?(:imagecontext) && imagecontext.blank?
    return true if respond_to?(:image_style_profile) && image_style_profile.blank?
    # Tables, employees, localization, and menu (taxes/tips optional)
    return true unless tablesettings.exists?(archived: false)
    return true unless employees.any?

    has_locales = restaurantlocales.any?
    has_default_locale = restaurantlocales.exists?(status: 'active', dfault: true)
    return true unless has_locales && has_default_locale

    has_any_menu = restaurant_menus
      .where.not(status: RestaurantMenu.statuses[:archived])
      .joins(:menu)
      .exists?(menus: { archived: false })
    return true unless has_any_menu

    false
  end

  # L2 cached complex queries
  def dashboard_summary
    self.class.cached_query("restaurant:#{id}:dashboard", cache_type: :dashboard) do
      Restaurant.joins(:menus, :ordrs)
        .select('restaurants.*,
                 COUNT(DISTINCT menus.id) as menu_count,
                 COUNT(DISTINCT ordrs.id) as order_count,
                 COALESCE(SUM(ordrs.gross), 0) as total_revenue')
        .where(id: id)
        .group('restaurants.id')
    end
  end

  def order_analytics(date_range = nil)
    cache_key = "restaurant:#{id}:order_analytics"
    cache_key += ":#{date_range[:start]}_#{date_range[:end]}" if date_range

    self.class.cached_query(cache_key, cache_type: :analytics) do
      query = ordrs.unscope(:order).select('ordrs.*,
                            COUNT(ordritems.id) as item_count,
                            SUM(ordritems.ordritemprice) as items_total')
        .joins(:ordritems)
        .group('ordrs.id')

      if date_range
        query = query.where('ordrs."orderedAt" >= ? AND ordrs."orderedAt" <= ?', date_range[:start], date_range[:end])
      end

      query
    end
  end

  def revenue_summary
    self.class.cached_query("restaurant:#{id}:revenue", cache_type: :report) do
      ordrs.unscope(:order).select('DATE(ordrs."orderedAt") as order_date,
                    COUNT(*) as order_count,
                    SUM(ordrs.nett) as total_nett,
                    SUM(ordrs.service) as total_service,
                    SUM(ordrs.tax) as total_tax,
                    SUM(ordrs.gross) as total_gross')
        .group('DATE(ordrs."orderedAt")')
        .order(order_date: :desc)
    end
  end

  private

  def invalidate_restaurant_caches
    AdvancedCacheService.invalidate_restaurant_caches(id)
  end
end
