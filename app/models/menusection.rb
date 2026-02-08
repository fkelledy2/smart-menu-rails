class Menusection < ApplicationRecord
  include IdentityCache

  # Standard ActiveRecord associations
  belongs_to :menu
  has_many :menuitems, -> { reorder(sequence: :asc, id: :asc) }, dependent: :delete_all, counter_cache: :menuitems_count

  # Default currencies based on parent restaurant
  before_validation :default_tasting_currencies
  after_commit :enqueue_menu_item_search_reindex, on: %i[create update destroy]

  # IdentityCache configuration
  cache_index :id
  cache_index :menu_id

  # Cache associations
  cache_belongs_to :menu
  cache_has_many :menuitems, embed: :ids

  # Responsive image helpers
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

  def image_srcset
    [
      "#{thumb_url} 200w",
      "#{medium_url} 600w",
      "#{large_url} 1000w",
    ].join(', ')
  end

  def image_sizes
    '(max-width: 600px) 200px, (max-width: 1200px) 600px, 1000px'
  end
  include ImageUploader::Attachment(:image)

  has_many :menusectionlocales
  has_one :genimage, dependent: :destroy

  def localised_name(locale)
    # Case-insensitive locale lookup
    locale_code = locale.to_s.downcase
    restaurant = menu&.restaurant

    rl = nil
    if restaurant&.association(:restaurantlocales)&.loaded?
      rl = restaurant.restaurantlocales.find { |x| x.locale.to_s.downcase == locale_code }
    end
    if rl.nil? && restaurant&.id
      rl = Restaurantlocale.where(restaurant_id: restaurant.id, locale: locale_code).first
      rl ||= Restaurantlocale.where(restaurant_id: restaurant.id).where('LOWER(locale) = ?', locale_code).first
    end

    return name if rl&.dfault == true

    mil = if association(:menusectionlocales).loaded?
            menusectionlocales.find { |x| x.locale.to_s.downcase == locale_code }
          else
            Menusectionlocale.where(menusection_id: id, locale: locale_code).first ||
              Menusectionlocale.where(menusection_id: id).where('LOWER(locale) = ?', locale_code).first
          end

    mil&.name.presence || name
  end

  def localised_description(locale)
    # Case-insensitive locale lookup
    locale_code = locale.to_s.downcase
    restaurant = menu&.restaurant

    rl = nil
    if restaurant&.association(:restaurantlocales)&.loaded?
      rl = restaurant.restaurantlocales.find { |x| x.locale.to_s.downcase == locale_code }
    end
    if rl.nil? && restaurant&.id
      rl = Restaurantlocale.where(restaurant_id: restaurant.id, locale: locale_code).first
      rl ||= Restaurantlocale.where(restaurant_id: restaurant.id).where('LOWER(locale) = ?', locale_code).first
    end

    return description if rl&.dfault == true

    mil = if association(:menusectionlocales).loaded?
            menusectionlocales.find { |x| x.locale.to_s.downcase == locale_code }
          else
            Menusectionlocale.where(menusection_id: id, locale: locale_code).first ||
              Menusectionlocale.where(menusection_id: id).where('LOWER(locale) = ?', locale_code).first
          end

    mil&.description.presence || description
  end

  enum :status, {
    inactive: 0,
    active: 1,
    archived: 2,
  }
  def gen_image_theme
    genimage&.id
  end

  def fromOffset
    (fromhour * 60) + frommin
  end

  def toOffset
    (tohour * 60) + tomin
  end

  validates :name, presence: true
  validates :status, presence: true

  # Scopes
  scope :tasting, -> { where(tasting_menu: true) }

  # Tasting menu validations
  with_options if: -> { tasting_menu? } do
    validates :price_per, inclusion: { in: %w[person table] }
    validates :tasting_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :tasting_currency, presence: true, if: -> { tasting_price_cents.present? }
  end

  with_options if: -> { tasting_menu? && allow_pairing? } do
    validates :pairing_price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
    validates :pairing_currency, presence: true, if: -> { pairing_price_cents.present? }
  end

  def tasting_price_amount
    return nil if tasting_price_cents.nil?

    tasting_price_cents.to_i / 100.0
  end

  def tasting_price_amount=(value)
    self.tasting_price_cents = if value.present?
                                 (value.to_f * 100).round
                               else
                                 nil
                               end
  end

  def pairing_price_amount
    return nil if pairing_price_cents.nil?

    pairing_price_cents.to_i / 100.0
  end

  def pairing_price_amount=(value)
    self.pairing_price_cents = if value.present?
                                 (value.to_f * 100).round
                               else
                                 nil
                               end
  end

  def enqueue_menu_item_search_reindex
    return if menu_id.blank?

    v = ENV.fetch('SMART_MENU_VECTOR_SEARCH_ENABLED', nil)
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

  private

  def default_tasting_currencies
    parent_currency = menu&.restaurant&.currency
    return unless tasting_menu?

    self.tasting_currency ||= parent_currency if tasting_price_cents.present?
    if allow_pairing? && pairing_price_cents.present?
      self.pairing_currency ||= parent_currency
    end
  end
end
