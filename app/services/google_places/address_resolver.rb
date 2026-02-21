# frozen_string_literal: true

module GooglePlaces
  class AddressResolver < ExternalApiClient
    def default_config
      super.merge(
        base_uri: 'https://maps.googleapis.com/maps/api/place',
      )
    end

    def validate_config!
      super
      raise ConfigurationError, 'api_key is required' if config[:api_key].blank?
    end

    # Resolve a free-text address into structured address components.
    # Uses Google Places "Find Place from Text" to locate the place,
    # then fetches full details via PlaceDetails.
    #
    # @param address_text [String] free-text address (e.g. "123 Main St, Dublin 2")
    # @param restaurant_name [String] optional restaurant name for better matching
    # @return [Hash, nil] structured result with :address_components, :formatted_address,
    #   :place_id, :location, or nil if resolution failed
    def resolve(address_text:, restaurant_name: nil)
      text = address_text.to_s.strip
      return nil if text.blank?

      query = restaurant_name.present? ? "#{restaurant_name}, #{text}" : text

      place_id = find_place_id(query)
      return nil if place_id.blank?

      details_client = GooglePlaces::PlaceDetails.new(api_key: config[:api_key])
      details = details_client.fetch!(place_id)
      return nil unless details.is_a?(Hash)

      {
        'place_id' => details[:place_id],
        'formatted_address' => details[:formatted_address],
        'address_components' => Array(details[:address_components]),
        'location' => details[:location],
        'types' => Array(details[:types]),
        'international_phone_number' => details[:international_phone_number],
        'resolved_at' => Time.current.iso8601,
      }.compact
    rescue StandardError => e
      Rails.logger.warn "[AddressResolver] Failed to resolve address: #{e.message}"
      nil
    end

    # Extract structured fields from address_components array.
    # @param components [Array<Hash>] Google Places address_components
    # @return [Hash] with keys: :postcode, :country_code, :city, :state, :address1
    def self.extract_fields(components)
      comps = Array(components)

      postcode = comps.find { |c| Array(c['types']).include?('postal_code') }
                   &.dig('long_name')

      country_code = comps.find { |c| Array(c['types']).include?('country') }
                       &.dig('short_name')

      city = (comps.find { |c| Array(c['types']).include?('locality') } ||
              comps.find { |c| Array(c['types']).include?('postal_town') })
               &.dig('long_name')

      state = comps.find { |c| Array(c['types']).include?('administrative_area_level_1') }
                &.dig('short_name')

      street_number = comps.find { |c| Array(c['types']).include?('street_number') }
                        &.dig('long_name')
      route = comps.find { |c| Array(c['types']).include?('route') }
                &.dig('long_name')
      address1 = [street_number, route].compact.join(' ').presence

      {
        postcode: postcode&.strip,
        country_code: country_code&.strip&.upcase,
        city: city&.strip,
        state: state&.strip,
        address1: address1,
      }.compact
    end

    private

    def find_place_id(query)
      response = get('/findplacefromtext/json', query: {
        input: query,
        inputtype: 'textquery',
        fields: 'place_id,formatted_address,geometry',
        key: config[:api_key],
      })

      body = response.parsed_response
      status = body['status'].to_s

      return nil unless %w[OK].include?(status)

      candidates = Array(body['candidates'])
      candidates.first&.dig('place_id')
    rescue StandardError => e
      Rails.logger.warn "[AddressResolver] Find place failed: #{e.message}"
      nil
    end
  end
end
