module GooglePlaces
  class PlaceDetails < ExternalApiClient
    def default_config
      super.merge(
        base_uri: 'https://maps.googleapis.com/maps/api/place',
      )
    end

    def validate_config!
      super
      raise ConfigurationError, 'api_key is required' if config[:api_key].blank?
    end

    def fetch!(place_id)
      pid = place_id.to_s.strip
      raise ArgumentError, 'place_id required' if pid.blank?

      response = get('/details/json', query: {
        place_id: pid,
        key: config[:api_key],
        fields: 'place_id,name,website,url,types,formatted_address,international_phone_number,address_components,geometry',
      },)

      body = response.parsed_response
      result = body['result'] || {}

      {
        place_id: result['place_id'].to_s,
        name: result['name'].to_s,
        website: result['website'].to_s.presence,
        google_url: result['url'].to_s.presence,
        types: Array(result['types']),
        formatted_address: result['formatted_address'].to_s.presence,
        international_phone_number: result['international_phone_number'].to_s.presence,
        address_components: Array(result['address_components']),
        location: begin
          loc = result.dig('geometry', 'location')
          { lat: loc['lat'], lng: loc['lng'] } if loc.is_a?(Hash)
        rescue StandardError
          nil
        end,
      }
    end
  end
end
