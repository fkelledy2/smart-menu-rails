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
        fields: 'place_id,name,website,url,types,formatted_address,international_phone_number,address_components,geometry,opening_hours',
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
        opening_hours: parse_opening_hours(result['opening_hours']),
      }
    end

    private

    # Google Places opening_hours.periods format:
    # [{ "open": { "day": 0, "time": "1100" }, "close": { "day": 0, "time": "2300" } }, ...]
    # day: 0=Sunday, 1=Monday, ..., 6=Saturday
    # time: "HHMM" 24-hour format
    # Returns normalized array: [{ day: 0, open_hour: 11, open_min: 0, close_hour: 23, close_min: 0 }, ...]
    def parse_opening_hours(opening_hours)
      return nil if opening_hours.nil?

      periods = Array(opening_hours['periods'])
      return nil if periods.empty?

      # Check for 24/7 (single period with open day 0 time 0000 and no close)
      if periods.length == 1 && periods[0]['close'].nil?
        return (0..6).map do |day|
          { 'day' => day, 'open_hour' => 0, 'open_min' => 0, 'close_hour' => 23, 'close_min' => 59 }
        end
      end

      periods.filter_map do |period|
        open_data = period['open']
        close_data = period['close']
        next if open_data.nil?

        open_time = open_data['time'].to_s
        close_time = close_data&.dig('time').to_s

        next if open_time.length < 4

        {
          'day' => open_data['day'].to_i,
          'open_hour' => open_time[0..1].to_i,
          'open_min' => open_time[2..3].to_i,
          'close_hour' => close_time.length >= 4 ? close_time[0..1].to_i : 23,
          'close_min' => close_time.length >= 4 ? close_time[2..3].to_i : 59,
        }
      end
    rescue StandardError
      nil
    end
  end
end
