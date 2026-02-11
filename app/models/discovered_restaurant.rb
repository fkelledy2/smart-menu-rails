class DiscoveredRestaurant < ApplicationRecord
  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    blacklisted: 3,
  }

  SYNC_TO_RESTAURANT_FIELDS = %w[
    name
    website_url
    address1
    address2
    city
    state
    postcode
    country_code
    currency
    establishment_types
    google_place_id
    metadata
  ].freeze

  has_many :menu_sources, dependent: :destroy
  belongs_to :restaurant, optional: true

  after_commit :enqueue_restaurant_sync_if_needed, on: %i[create update]

  before_validation :normalize_establishment_types

  validates :city_name, presence: true
  validates :google_place_id, presence: true
  validates :name, presence: true
  validates :status, presence: true

  def place_details
    metadata.is_a?(Hash) ? (metadata['place_details'] || {}) : {}
  end

  def place_address_components
    Array(place_details['address_components'])
  end

  def inferred_address_component(type)
    place_address_components.find { |c| Array(c['types']).include?(type) }
  end

  def inferred_country_code
    inferred_address_component('country')&.dig('short_name')
  end

  def inferred_postcode
    inferred_address_component('postal_code')&.dig('long_name')
  end

  def inferred_city
    (inferred_address_component('locality') || inferred_address_component('postal_town'))&.dig('long_name')
  end

  def inferred_state
    inferred_address_component('administrative_area_level_1')&.dig('short_name')
  end

  def inferred_address1
    street_number = inferred_address_component('street_number')&.dig('long_name')
    route = inferred_address_component('route')&.dig('long_name')
    [street_number, route].compact.join(' ').presence
  end

  def effective_country_code
    country_code.presence || inferred_country_code
  end

  def suggested_currency
    return currency if currency.present?

    CountryCurrencyInference.new.infer(effective_country_code)
  rescue StandardError
    nil
  end

  def establishment_type_labels
    EstablishmentTypeInference.new.labels_for(establishment_types)
  rescue StandardError
    []
  end

  def establishment_type_label_text
    labels = establishment_type_labels
    labels.any? ? labels.join(' / ') : 'Unknown'
  end

  private

  def enqueue_restaurant_sync_if_needed
    return if restaurant_id.blank?
    return unless approved?

    changed_keys = previous_changes.keys
    return if (changed_keys & SYNC_TO_RESTAURANT_FIELDS).empty?

    SyncDiscoveredRestaurantToRestaurantJob.perform_later(discovered_restaurant_id: id)
  end

  def normalize_establishment_types
    return if establishment_types.blank?

    self.establishment_types = Array(establishment_types).map { |t| t.to_s.strip }.reject(&:blank?).uniq
  end
end
