class Restaurant < ApplicationRecord
  include ImageUploader::Attachment(:image)
  include IdentityCache
  include L2Cacheable

  # Standard ActiveRecord associations
  belongs_to :user

  has_many :tablesettings, dependent: :delete_all
  has_many :menus, dependent: :delete_all
  has_many :employees, dependent: :delete_all
  has_many :ordrs, dependent: :delete_all
  has_many :taxes, dependent: :delete_all
  has_many :tips, dependent: :delete_all
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
    Restaurantlocale.where(restaurant_id: id, status: 'active', dfault: true).first
  end

  def getLocale(locale)
    Restaurantlocale.where(restaurant_id: id, status: 'active', locale: locale).first
  end

  validates :name, presence: true
  validates :address1, presence: false
  validates :city, presence: false
  validates :postcode, presence: false
  validates :country, presence: false
  validates :status, presence: true

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
           .order('order_date DESC')
    end
  end

  private

  def invalidate_restaurant_caches
    AdvancedCacheService.invalidate_restaurant_caches(id)
  end
end
