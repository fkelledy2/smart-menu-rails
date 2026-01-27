class Restaurant < ApplicationRecord
  has_one :alcohol_policy, dependent: :destroy
  include ImageUploader::Attachment(:image)
  include IdentityCache
  include L2Cacheable

  # Standard ActiveRecord associations
  belongs_to :user

  has_many :tablesettings, dependent: :delete_all
  has_many :menus, dependent: :delete_all
  has_many :restaurant_menus, dependent: :delete_all
  has_many :shared_menus, through: :restaurant_menus, source: :menu
  has_many :employees, dependent: :delete_all

  def alcohol_allowed_now?(now: Time.zone.now)
    return false if respond_to?(:allow_alcohol) && !allow_alcohol
    return true unless alcohol_policy
    alcohol_policy.allowed_now?(now: now)
  end

  has_many :ordrs, dependent: :delete_all
  has_many :ordr_station_tickets, dependent: :delete_all
  has_many :taxes, dependent: :delete_all
  has_many :tips, dependent: :delete_all

  has_one :payment_profile, dependent: :destroy
  has_many :provider_accounts, dependent: :delete_all
  has_many :payment_attempts, dependent: :delete_all
  has_many :payment_refunds, dependent: :delete_all
  has_many :restaurantavailabilities, dependent: :delete_all
  has_many :menusections, through: :menus
  has_many :menuavailabilities, through: :menus
  has_one  :genimage, dependent: :destroy
  has_many :tracks, dependent: :delete_all
  has_many :restaurantlocales, dependent: :delete_all
  has_many :allergyns, dependent: :delete_all
  has_many :sizes, dependent: :delete_all
  has_many :ocr_menu_imports, dependent: :destroy

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

  def spotifyAuthUrl
    "/auth/spotify?restaurant_id=#{id}"
  end

  def spotifyPlaylistUrl
    "/restaurants/#{id}/tracks"
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
      Restaurantlocale.where(restaurant_id: id, status: 'active', dfault: true).first
    end
  end

  def getLocale(locale)
    requested = locale.to_s.downcase
    if association(:restaurantlocales).loaded?
      restaurantlocales.find { |rl| rl.status.to_s == 'active' && rl.locale.to_s.downcase == requested }
    else
      # Case-insensitive lookup to handle both 'it' and 'IT'
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
  def onboarding_next_section
    # 1) Details: require description, currency, and some address/location info
    details_ok = description.present? && currency.present? && (address1.present? || city.present? || postcode.present? || country.present?)
    return 'details' unless details_ok

    # 2) Tables: require at least one table setting
    return 'tables' unless tablesettings.any?

    # 3) Taxes and Tips: require at least one tax and one tip
    return 'taxes_and_tips' unless taxes.any? && tips.any?

    # 4) Localization: require at least one language and a default language set
    has_locales = restaurantlocales.any?
    has_default_locale = restaurantlocales.where(status: 'active', dfault: true).exists?
    return 'localization' unless has_locales && has_default_locale

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
    address_ok = address1.present? || city.present? || postcode.present? || country.present?
    return true unless address_ok
    # Context and image style profile
    return true if respond_to?(:imagecontext) && imagecontext.blank?
    return true if respond_to?(:image_style_profile) && image_style_profile.blank?
    # Tables, employees, taxes, tips, and localization
    return true unless tablesettings.any?
    return true unless employees.any?
    has_locales = restaurantlocales.any?
    has_default_locale = restaurantlocales.where(status: 'active', dfault: true).exists?
    return true unless has_locales && has_default_locale
    return true unless taxes.any?
    return true unless tips.any?
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
      query = ordrs.select('ordrs.*,
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
      ordrs.select('DATE(ordrs."orderedAt") as order_date,
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
