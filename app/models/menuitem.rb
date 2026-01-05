class Menuitem < ApplicationRecord
  include IdentityCache
  include ImageUploader::Attachment(:image)

  # Standard ActiveRecord associations
  has_many :menuitemlocales
  belongs_to :menusection
  has_many :menuitem_allergyn_mappings, dependent: :destroy
  has_many :allergyns, through: :menuitem_allergyn_mappings
  has_many :menuitem_tag_mappings, dependent: :destroy
  has_many :tags, through: :menuitem_tag_mappings
  has_many :menuitem_size_mappings, dependent: :destroy
  has_many :sizes, through: :menuitem_size_mappings
  has_many :menuitem_ingredient_mappings, dependent: :destroy
  has_many :ingredients, through: :menuitem_ingredient_mappings
  has_many :ordritems, dependent: :destroy
  has_one :inventory, dependent: :destroy
  has_one :genimage, dependent: :destroy

  # IdentityCache configuration
  cache_index :id
  cache_index :menusection_id
  cache_index :status
  cache_index :menusection_id, :status
  cache_index :menusection_id, :sequence

  # Cache associations
  cache_belongs_to :menusection
  cache_has_many :menuitemlocales, embed: :ids
  cache_has_many :menuitem_allergyn_mappings, embed: :ids
  cache_has_many :menuitem_size_mappings, embed: :ids
  cache_has_many :menuitem_ingredient_mappings, embed: :ids
  cache_has_many :menuitem_tag_mappings, embed: :ids
  cache_has_many :ordritems, embed: :ids
  cache_has_one :inventory, embed: :id
  cache_has_one :genimage, embed: :id

  # Cache invalidation hooks
  after_update :invalidate_menuitem_caches
  after_destroy :invalidate_menuitem_caches

  after_commit :enqueue_menu_item_search_reindex, on: %i[create update destroy]

  def localised_name(locale)
    # Case-insensitive locale lookup
    mil = Menuitemlocale.where(menuitem_id: id).where('LOWER(locale) = ?', locale.to_s.downcase).first
    rl = Restaurantlocale.where(restaurant_id: menusection.menu.restaurant.id).where('LOWER(locale) = ?', locale.to_s.downcase).first
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
    mil = Menuitemlocale.where(menuitem_id: id).where('LOWER(locale) = ?', locale.to_s.downcase).first
    rl = Restaurantlocale.where(restaurant_id: menusection.menu.restaurant.id).where('LOWER(locale) = ?', locale.to_s.downcase).first
    if rl&.dfault == true
      description
    elsif mil
      mil.description
    else
      description
    end
  end

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }

  enum :itemtype, {
    food: 0,
    beverage: 1,
    wine: 2,
  }

  def genImageId
    if genimage
      genimage.id
    else
      -1
    end
  end

  def image_url_or_fallback(size = nil)
    url = if image_attacher.derivatives&.key?(size)
      image_url(size)
    else
      image_url
    end
    cache_busted(url)
  end

  def thumb_url
    image_url_or_fallback(:thumb)
  end

  # Scopes
  scope :tasting_items, -> { joins(:menusection).where(menusections: { tasting_menu: true }) }
  scope :non_tasting_items, -> { joins(:menusection).where(menusections: { tasting_menu: false }) }
  scope :visible, -> { where(hidden: [false, nil]) }
  scope :hidden_items, -> { where(hidden: true) }
  scope :carrier, -> { where(tasting_carrier: true) }

  # Validations for tasting supplements and ordering
  with_options if: -> { menusection&.tasting_menu? } do
    validates :tasting_supplement_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :tasting_supplement_currency, presence: true, if: -> { tasting_supplement_cents.present? }
    validates :course_order, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  end

  # Only one carrier per tasting section
  validates :tasting_carrier, inclusion: { in: [true, false] }
  validates :hidden, inclusion: { in: [true, false] }
  validates :tasting_carrier, uniqueness: { scope: :menusection_id, message: 'already set for this section' }, if: :tasting_carrier?

  before_validation :ensure_hidden_when_carrier

  def ensure_hidden_when_carrier
    if tasting_carrier?
      self.hidden = true
    end
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
      "#{large_url} 1000w",
    ].join(', ')
  end

  # Returns a default sizes attribute for responsive images
  def image_sizes
    '(max-width: 600px) 200px, (max-width: 1200px) 600px, 1000px'
  end

  # Get WebP URL if available, fallback to original
  def webp_url(size = :medium)
    return nil if image.blank?

    begin
      # Check if WebP derivative exists
      webp_key = :"#{size}_webp"
      url = if image_attacher.derivatives&.key?(webp_key)
        image_url(webp_key)
      else
        image_url_or_fallback(size)
      end
      cache_busted(url)
    rescue StandardError => e
      Rails.logger.error "[Menuitem] Error getting WebP URL for #{id}: #{e.message}"
      cache_busted(image_url_or_fallback(size))
    end
  end

  # Generate WebP srcset for responsive images
  def webp_srcset
    return '' if image.blank?

    begin
      srcset_parts = []

      # Add WebP derivatives if they exist
      if image_attacher.derivatives&.key?(:thumb_webp)
        srcset_parts << "#{image_url(:thumb_webp)} 200w"
      end

      if image_attacher.derivatives&.key?(:medium_webp)
        srcset_parts << "#{image_url(:medium_webp)} 600w"
      end

      if image_attacher.derivatives&.key?(:large_webp)
        srcset_parts << "#{image_url(:large_webp)} 1000w"
      end

      srcset_parts.join(', ')
    rescue StandardError => e
      Rails.logger.error "[Menuitem] Error generating WebP srcset for #{id}: #{e.message}"
      ''
    end
  end

  # Enhanced srcset that includes WebP when available
  def image_srcset_with_webp
    webp = webp_srcset
    webp.presence || image_srcset
  end

  # Check if WebP derivatives exist
  def has_webp_derivatives?
    image.present? &&
      image_attacher.derivatives&.key?(:thumb_webp) &&
      image_attacher.derivatives.key?(:medium_webp) &&
      image_attacher.derivatives.key?(:large_webp)
  end

  validates :inventory, presence: false
  validates :name, presence: true
  validates :itemtype, presence: true
  validates :status, presence: true
  validates :preptime, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :price, presence: true, numericality: { only_float: true, greater_than_or_equal_to: 0 }
  validates :calories, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  # Alcohol fields
  validates :abv, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :abv_must_be_nil_or_zero_when_non_alcoholic

  def alcoholic?
    self[:alcoholic] == true && alcohol_classification != 'non_alcoholic'
  end

  private

  def abv_must_be_nil_or_zero_when_non_alcoholic
    return if alcoholic?
    return if abv.blank? || abv.to_d == 0.to_d

    errors.add(:abv, :non_alcoholic_must_be_zero)
  end

  # Append updated_at timestamp to bust browser caches when images change
  def cache_busted(url)
    return url if url.blank?
    ts = updated_at&.to_i
    return url unless ts

    begin
      u = URI.parse(url)
      # Do not modify pre-signed S3 URLs (X-Amz-*) or if a version param already exists
      query = u.query.to_s
      has_s3_sig = query.include?('X-Amz-') || query.include?('X-Amz-Signature')
      has_version = CGI.parse(query).key?('v')
      return url if has_s3_sig || has_version

      params = CGI.parse(query)
      params['v'] = [ts.to_s]
      u.query = URI.encode_www_form(params)
      u.to_s
    rescue
      # Fallback to simple concatenation if URI parsing fails
      separator = url.include?('?') ? '&' : '?'
      "#{url}#{separator}v=#{ts}"
    end
  end

  def invalidate_menuitem_caches
    AdvancedCacheService.invalidate_menuitem_caches(id)
    AdvancedCacheService.invalidate_menu_caches(menusection.menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(menusection.menu.restaurant.id)
  end

  def enqueue_menu_item_search_reindex
    menu_id = menusection&.menu_id
    return if menu_id.blank?

    v = ENV['SMART_MENU_VECTOR_SEARCH_ENABLED']
    vector_enabled = if v.nil? || v.to_s.strip == ''
                       true
                     else
                       v.to_s.downcase == 'true'
                     end
    return unless vector_enabled
    return if ENV['SMART_MENU_ML_URL'].to_s.strip == ''

    MenuItemSearchIndexJob.perform_async(menu_id)
  rescue StandardError
    nil
  end
end
