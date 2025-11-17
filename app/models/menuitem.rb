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
      if image_attacher.derivatives&.key?(webp_key)
        image_url(webp_key)
      else
        # Fallback to original size
        image_url_or_fallback(size)
      end
    rescue StandardError => e
      Rails.logger.error "[Menuitem] Error getting WebP URL for #{id}: #{e.message}"
      image_url_or_fallback(size)
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

  private

  def invalidate_menuitem_caches
    AdvancedCacheService.invalidate_menuitem_caches(id)
    AdvancedCacheService.invalidate_menu_caches(menusection.menu.id)
    AdvancedCacheService.invalidate_restaurant_caches(menusection.menu.restaurant.id)
  end
end
