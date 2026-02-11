class DiscoveredRestaurantRestaurantSyncService
  def initialize(discovered_restaurant:, restaurant:)
    @discovered_restaurant = discovered_restaurant
    @restaurant = restaurant
  end

  def sync!
    attrs = sync_attributes
    return false if attrs.blank?

    @restaurant.update!(attrs)

    meta = @discovered_restaurant.metadata.is_a?(Hash) ? @discovered_restaurant.metadata : {}
    meta['last_synced_at'] = Time.current.iso8601
    @discovered_restaurant.update_column(:metadata, meta)

    true
  end

  def sync_attributes
    attrs = {
      name: @discovered_restaurant.name,
      description: @discovered_restaurant.description.presence,
      city: preferred_city,
      address1: preferred_field(:address1, inferred: @discovered_restaurant.inferred_address1),
      address2: preferred_field(:address2, inferred: nil),
      state: preferred_field(:state, inferred: @discovered_restaurant.inferred_state),
      postcode: preferred_field(:postcode, inferred: @discovered_restaurant.inferred_postcode),
      country: preferred_field(:country_code, inferred: @discovered_restaurant.inferred_country_code),
      currency: preferred_field(:currency, inferred: @discovered_restaurant.suggested_currency),
      latitude: preferred_location(:lat),
      longitude: preferred_location(:lng),
      google_place_id: @discovered_restaurant.google_place_id,
      establishment_types: inferred_establishment_types,
      imagecontext: @discovered_restaurant.image_context.presence,
      image_style_profile: @discovered_restaurant.image_style_profile.presence,
    }

    attrs.compact
  end

  private

  def preferred_city
    explicit = @discovered_restaurant.city.presence
    return explicit if explicit.present?

    return nil if @restaurant.city.present?

    @discovered_restaurant.inferred_city.presence || @discovered_restaurant.city_name.presence
  end

  def preferred_field(field, inferred:)
    explicit = @discovered_restaurant.public_send(field).presence
    return explicit if explicit.present?

    restaurant_field = restaurant_field_for(field)
    return nil if restaurant_field && @restaurant.public_send(restaurant_field).present?

    inferred.presence
  end

  def restaurant_field_for(discovered_field)
    return :country if discovered_field == :country_code

    discovered_field
  end

  def inferred_location
    place_details = @discovered_restaurant.place_details
    place_details['location'].is_a?(Hash) ? place_details['location'] : {}
  end

  def preferred_location(key)
    return nil if key == :lat && @restaurant.latitude.present?
    return nil if key == :lng && @restaurant.longitude.present?

    inferred_location[key].presence
  end

  def inferred_establishment_types
    explicit = @discovered_restaurant.establishment_types.presence
    return explicit if explicit.present?

    google_types = Array(@discovered_restaurant.place_details['types'])
    inferred = EstablishmentTypeInference.new.infer_from_google_places_types(google_types)
    inferred.presence
  rescue StandardError
    nil
  end
end
