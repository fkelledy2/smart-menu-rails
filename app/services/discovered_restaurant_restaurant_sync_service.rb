class DiscoveredRestaurantRestaurantSyncService
  def initialize(discovered_restaurant:, restaurant:)
    @discovered_restaurant = discovered_restaurant
    @restaurant = restaurant
  end

  # Google Places day index → Restaurantavailability dayofweek enum
  GOOGLE_DAY_TO_DAYOFWEEK = {
    0 => :sunday,
    1 => :monday,
    2 => :tuesday,
    3 => :wednesday,
    4 => :thursday,
    5 => :friday,
    6 => :saturday,
  }.freeze

  def sync!
    attrs = sync_attributes
    return false if attrs.blank?

    @restaurant.update!(attrs)
    sync_opening_hours!
    sync_default_locale!
    sync_default_table!

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

  def sync_opening_hours!
    opening_hours = @discovered_restaurant.place_details['opening_hours']
    return if opening_hours.blank?

    # Don't overwrite manually-set hours on claimed restaurants
    return if @restaurant.restaurantavailabilities.exists? && !@restaurant.unclaimed?

    # Track which days we've seen from the Google data
    seen_days = Set.new

    opening_hours.each do |period|
      day_index = period['day'].to_i
      dayofweek = GOOGLE_DAY_TO_DAYOFWEEK[day_index]
      next if dayofweek.nil?

      seen_days << dayofweek

      availability = @restaurant.restaurantavailabilities.find_or_initialize_by(
        dayofweek: dayofweek,
        sequence: 1,
      )

      availability.starthour = period['open_hour'].to_i
      availability.startmin = period['open_min'].to_i
      availability.endhour = period['close_hour'].to_i
      availability.endmin = period['close_min'].to_i
      availability.status = :open
      availability.save!
    end

    # Mark unseen days as closed
    GOOGLE_DAY_TO_DAYOFWEEK.each_value do |dayofweek|
      next if seen_days.include?(dayofweek)

      availability = @restaurant.restaurantavailabilities.find_or_initialize_by(
        dayofweek: dayofweek,
        sequence: 1,
      )
      availability.status = :closed
      availability.save!
    end
  rescue StandardError => e
    Rails.logger.warn("[SyncService] sync_opening_hours! failed for restaurant_id=#{@restaurant.id}: #{e.class}: #{e.message}")
  end

  # Country code → primary locale mapping
  COUNTRY_TO_LOCALE = {
    'IE' => 'en', 'GB' => 'en', 'US' => 'en', 'AU' => 'en', 'NZ' => 'en', 'CA' => 'en',
    'ZA' => 'en', 'IN' => 'en', 'SG' => 'en', 'PH' => 'en', 'NG' => 'en', 'KE' => 'en',
    'FR' => 'fr', 'BE' => 'fr', 'LU' => 'fr', 'MC' => 'fr', 'SN' => 'fr', 'CI' => 'fr',
    'DE' => 'de', 'AT' => 'de', 'CH' => 'de', 'LI' => 'de',
    'IT' => 'it', 'SM' => 'it', 'VA' => 'it',
    'ES' => 'es', 'MX' => 'es', 'AR' => 'es', 'CO' => 'es', 'CL' => 'es', 'PE' => 'es',
    'VE' => 'es', 'EC' => 'es', 'UY' => 'es', 'PY' => 'es', 'BO' => 'es', 'CR' => 'es',
    'PA' => 'es', 'GT' => 'es', 'HN' => 'es', 'SV' => 'es', 'NI' => 'es', 'DO' => 'es',
    'CU' => 'es', 'PR' => 'es',
    'PT' => 'pt', 'BR' => 'pt', 'AO' => 'pt', 'MZ' => 'pt',
    'NL' => 'nl', 'SR' => 'nl',
    'SE' => 'sv', 'NO' => 'nb', 'DK' => 'da', 'FI' => 'fi', 'IS' => 'is',
    'PL' => 'pl', 'CZ' => 'cs', 'SK' => 'sk', 'HU' => 'hu', 'RO' => 'ro',
    'HR' => 'hr', 'SI' => 'sl', 'RS' => 'sr', 'BG' => 'bg', 'UA' => 'uk',
    'RU' => 'ru', 'BY' => 'ru',
    'GR' => 'el', 'CY' => 'el',
    'TR' => 'tr', 'IL' => 'he', 'SA' => 'ar', 'AE' => 'ar', 'EG' => 'ar',
    'MA' => 'ar', 'QA' => 'ar', 'KW' => 'ar', 'BH' => 'ar', 'OM' => 'ar',
    'JP' => 'ja', 'KR' => 'ko', 'CN' => 'zh', 'TW' => 'zh', 'HK' => 'zh',
    'TH' => 'th', 'VN' => 'vi', 'ID' => 'id', 'MY' => 'ms',
    'EE' => 'et', 'LV' => 'lv', 'LT' => 'lt',
    'MT' => 'mt',
  }.freeze

  def sync_default_table!
    return if @restaurant.tablesettings.where(archived: [false, nil]).exists?

    @restaurant.tablesettings.create!(
      name: 'T1',
      status: :free,
      tabletype: :indoor,
      capacity: 4,
      sequence: 1,
    )
  rescue StandardError => e
    Rails.logger.warn("[SyncService] sync_default_table! failed for restaurant_id=#{@restaurant.id}: #{e.class}: #{e.message}")
  end

  def sync_default_locale!
    country = @restaurant.country.to_s.strip.upcase
    locale = COUNTRY_TO_LOCALE[country]
    return if locale.blank?

    # Only add if the restaurant has no locales yet
    return if @restaurant.restaurantlocales.where.not(status: :archived).exists?

    @restaurant.restaurantlocales.create!(
      locale: locale,
      status: :active,
      dfault: true,
    )
  rescue StandardError => e
    Rails.logger.warn("[SyncService] sync_default_locale! failed for restaurant_id=#{@restaurant.id}: #{e.class}: #{e.message}")
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
