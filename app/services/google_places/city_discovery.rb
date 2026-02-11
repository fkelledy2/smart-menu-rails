module GooglePlaces
  class CityDiscovery < ExternalApiClient
    DEFAULT_PLACE_TYPES = %w[restaurant bar wine_bar whiskey_bar].freeze

    def default_config
      super.merge(
        base_uri: 'https://maps.googleapis.com/maps/api/place',
      )
    end

    def validate_config!
      super
      raise ConfigurationError, 'api_key is required' if config[:api_key].blank?
    end

    def discover!(city_query:, place_types:)
      city = city_query.to_s.strip
      raise ArgumentError, 'city_query required' if city.blank?

      city_place = resolve_city_place!(city)

      types = Array(place_types).map { |t| t.to_s.strip }.reject(&:blank?).uniq
      types = DEFAULT_PLACE_TYPES if types.blank?

      types.each do |type|
        discover_places_by_type!(city_place: city_place, place_type: type)
      end

      true
    end

    private

    def resolve_city_place!(city)
      body = city_text_search!(city)
      result = pick_city_result(body, fallback_name: city)

      if result.blank?
        stripped = city.to_s.split(',').first.to_s.strip
        if stripped.present? && stripped != city
          body = city_text_search!(stripped)
          result = pick_city_result(body, fallback_name: stripped)
        end
      end

      raise ApiError, "City not found: #{city}" if result.blank?

      {
        name: result['name'].to_s.presence || city,
        place_id: result['place_id'].to_s,
      }
    end

    def city_text_search!(query)
      response = get('/textsearch/json', query: {
        query: query,
        key: config[:api_key],
      })

      body = response.parsed_response
      status = body['status'].to_s

      if status.present? && !%w[OK ZERO_RESULTS].include?(status)
        msg = body['error_message'].to_s.presence
        raise ApiError, "Google Places textsearch failed (status=#{status})#{msg ? ": #{msg}" : ''}"
      end

      body
    end

    def pick_city_result(body, fallback_name:)
      results = Array(body['results'])

      locality_like = results.find do |r|
        types = Array(r['types']).map(&:to_s)
        (types & %w[locality postal_town administrative_area_level_3 administrative_area_level_2]).any?
      end

      locality_like || results.first
    end

    def discover_places_by_type!(city_place:, place_type:)
      details_client = GooglePlaces::PlaceDetails.new(api_key: config[:api_key])
      pdf_downloader = MenuDiscovery::PdfDownloader.new

      response = get('/textsearch/json', query: {
        query: "#{place_type} in #{city_place[:name]}",
        key: config[:api_key],
        type: place_type,
      })

      body = response.parsed_response
      Array(body['results']).each do |r|
        place_id = r['place_id'].to_s
        next if place_id.blank?

        details = begin
          details_client.fetch!(place_id)
        rescue StandardError
          nil
        end

        website_url = details.is_a?(Hash) ? details[:website].to_s.presence : nil
        next if website_url.blank?

        DiscoveredRestaurant.find_or_initialize_by(google_place_id: place_id).tap do |dr|
          dr.city_name = city_place[:name]
          dr.city_place_id = city_place[:place_id]
          dr.name = r['name'].to_s
          dr.website_url = website_url
          dr.discovered_at ||= Time.current

          inferred_types = EstablishmentTypeInference.new.infer_from_google_places_types(Array(details[:types]) + Array(r['types']))
          dr.establishment_types = inferred_types if inferred_types.any?

          dr.metadata = (dr.metadata || {})
            .merge('place_types' => Array(r['types']))
            .merge(
              'place_details' => {
                'formatted_address' => details[:formatted_address],
                'international_phone_number' => details[:international_phone_number],
                'google_url' => details[:google_url],
                'types' => Array(details[:types]),
                'address_components' => Array(details[:address_components]),
                'location' => details[:location],
              }.compact,
            )
          dr.save!

          begin
            finder = MenuDiscovery::WebsiteMenuFinder.new(base_url: website_url)
            pdf_urls = finder.find_menu_pdfs

            pdf_urls.each do |pdf_url|
              ms = dr.menu_sources.find_or_create_by!(source_url: pdf_url) do |m|
                m.source_type = :pdf
                m.status = :active
              end

              next if ms.latest_file.attached?

              tempfile = pdf_downloader.download(pdf_url)
              next if tempfile.nil?

              filename = File.basename(URI.parse(pdf_url).path.to_s.presence || 'menu.pdf')
              filename = 'menu.pdf' if filename.blank?

              ms.latest_file.attach(
                io: tempfile,
                filename: filename,
                content_type: 'application/pdf',
              )
            ensure
              tempfile&.close
              tempfile&.unlink
            end
          rescue StandardError
            nil
          end
        end
      end

      true
    end
  end
end
