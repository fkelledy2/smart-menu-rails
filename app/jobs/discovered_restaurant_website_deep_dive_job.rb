class DiscoveredRestaurantWebsiteDeepDiveJob < ApplicationJob
  queue_as :default

  def perform(discovered_restaurant_id:, triggered_by_user_id: nil)
    dr = DiscoveredRestaurant.find_by(id: discovered_restaurant_id)
    return if dr.nil?

    base_url = dr.website_url.to_s.strip
    place_details = fetch_place_details(dr)

    robots_checker = MenuDiscovery::RobotsTxtChecker.new
    crawl_evidence = base_url.present? ? robots_checker.evidence(base_url) : {}

    website_result = if base_url.present? && crawl_evidence['robots_allowed'] != false
                       extractor = MenuDiscovery::WebsiteContactExtractor.new(base_url: base_url, robots_checker: robots_checker)
                       extractor.extract
                     elsif base_url.present?
                       { 'source_base_url' => base_url, 'skipped' => 'robots_txt_blocked', 'extracted_at' => Time.current.iso8601 }
                     else
                       {
                         'source_base_url' => nil,
                         'visited_urls' => [],
                         'emails' => [],
                         'phones' => [],
                         'address_candidates' => [],
                         'extracted_at' => Time.current.iso8601,
                       }
                     end

    updated = dr.metadata || {}
    updated['crawl_evidence'] = (updated['crawl_evidence'].is_a?(Hash) ? updated['crawl_evidence'] : {}).merge(crawl_evidence) if crawl_evidence.present?
    updated['website_deep_dive'] = website_result.merge(
      'triggered_by_user_id' => triggered_by_user_id,
      'status' => 'completed',
      'error' => nil,
    ).compact

    if place_details.present?
      updated['place_details'] = (updated['place_details'].is_a?(Hash) ? updated['place_details'] : {}).merge(place_details)
    end

    now = Time.current.iso8601
    fs = (updated['field_sources'].is_a?(Hash) ? updated['field_sources'] : {})

    infer = EstablishmentTypeInference.new
    google_types = infer.infer_from_google_places_types(Array(place_details && place_details['types']))
    website_types = Array(website_result['context_types'])
    inferred_types = (google_types + website_types).map(&:to_s).uniq
    if inferred_types.any?
      dr.establishment_types = inferred_types
      sources = []
      sources << 'google_places' if google_types.any?
      sources << 'website' if website_types.any?
      fs['establishment_types'] = { 'source' => sources.join('+'), 'updated_at' => now }
    end

    if dr.country_code.blank?
      inferred_country = Array(place_details && place_details['address_components'])
        .find { |c| Array(c['types']).include?('country') }
        &.dig('short_name')
      if inferred_country.present?
        dr.country_code = inferred_country.to_s.strip.upcase
        fs['country_code'] = { 'source' => 'google_places', 'updated_at' => now }
      end
    end

    if dr.postcode.blank?
      inferred_postcode = Array(place_details && place_details['address_components'])
        .find { |c| Array(c['types']).include?('postal_code') }
        &.dig('long_name')
      if inferred_postcode.present?
        dr.postcode = inferred_postcode.to_s.strip
        fs['postcode'] = { 'source' => 'google_places', 'updated_at' => now }
      end
    end

    if dr.city.blank?
      inferred_city = begin
        comps = Array(place_details && place_details['address_components'])
        (comps.find { |c| Array(c['types']).include?('locality') } || comps.find { |c| Array(c['types']).include?('postal_town') })&.dig('long_name')
      rescue StandardError
        nil
      end
      if inferred_city.present?
        dr.city = inferred_city.to_s.strip
        fs['city'] = { 'source' => 'google_places', 'updated_at' => now }
      end
    end

    if dr.state.blank?
      inferred_state = Array(place_details && place_details['address_components'])
        .find { |c| Array(c['types']).include?('administrative_area_level_1') }
        &.dig('short_name')
      if inferred_state.present?
        dr.state = inferred_state.to_s.strip
        fs['state'] = { 'source' => 'google_places', 'updated_at' => now }
      end
    end

    if dr.address1.blank?
      best_address = Array(website_result['address_candidates']).compact_blank.first
      if best_address.present?
        dr.address1 = best_address.to_s.strip
        fs['address1'] = { 'source' => 'website', 'updated_at' => now }
      end
    end

    if dr.currency.blank? && dr.country_code.present?
      inferred_currency = CountryCurrencyInference.new.infer(dr.country_code)
      if inferred_currency.present?
        dr.currency = inferred_currency
        fs['currency'] = { 'source' => 'inferred', 'updated_at' => now }
      end
    end

    if dr.preferred_phone.blank?
      candidates = Array(website_result['phones']).compact_blank
      google_phone = place_details && place_details['international_phone_number']
      candidates << google_phone if google_phone.present?
      candidates = candidates.map { |p| p.to_s.strip }.compact_blank.uniq

      if candidates.length == 1
        dr.preferred_phone = candidates.first
        fs['preferred_phone'] = { 'source' => 'website', 'updated_at' => now }
      end
    end

    if dr.preferred_email.blank?
      candidates = Array(website_result['emails']).compact_blank
      candidates = candidates.map { |e| e.to_s.strip.downcase }.compact_blank.uniq

      if candidates.length == 1
        dr.preferred_email = candidates.first
        fs['preferred_email'] = { 'source' => 'website', 'updated_at' => now }
      end
    end

    raw_text = website_result.dig('about', 'text').to_s.strip
    text_source = 'about'
    if raw_text.blank?
      raw_text = website_result['homepage_text'].to_s.strip
      text_source = 'homepage'
    end

    generator = MenuDiscovery::RestaurantDescriptionGenerator.new
    ai_description = generator.generate(
      raw_about_text: raw_text.presence || dr.name,
      restaurant_name: dr.name,
      establishment_types: Array(dr.establishment_types),
      website_url: base_url,
    )

    if ai_description.present?
      dr.description = ai_description
      fs['description'] = { 'source' => 'ai_generated', 'updated_at' => now }
    elsif raw_text.present?
      dr.description = raw_text
      fs['description'] = { 'source' => "website_#{text_source}", 'updated_at' => now }
    end

    image_gen = MenuDiscovery::RestaurantImageProfileGenerator.new
    image_profile = image_gen.generate(
      raw_text: raw_text.presence || dr.name,
      restaurant_name: dr.name,
      description: dr.description,
      establishment_types: Array(dr.establishment_types),
      website_url: base_url,
    )
    if image_profile['image_context'].present?
      dr.image_context = image_profile['image_context']
      fs['image_context'] = { 'source' => 'ai_generated', 'updated_at' => now }
    end
    if image_profile['image_style_profile'].present?
      dr.image_style_profile = image_profile['image_style_profile']
      fs['image_style_profile'] = { 'source' => 'ai_generated', 'updated_at' => now }
    end

    updated['field_sources'] = fs
    dr.metadata = updated
    dr.save!
  rescue StandardError => e
    return if dr.nil?

    dr.metadata = (dr.metadata || {}).merge(
      'website_deep_dive' => {
        'source_base_url' => base_url,
        'error' => e.message,
        'extracted_at' => Time.current.iso8601,
        'status' => 'failed',
        'triggered_by_user_id' => triggered_by_user_id,
      }.compact,
    )
    dr.save!
  end

  private

  def fetch_place_details(dr)
    place_id = dr.google_place_id.to_s.strip
    return nil if place_id.blank?

    key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil) || ENV.fetch('GOOGLE_MAPS_BROWSER_API_KEY', nil)
    key ||= begin
      Rails.application.credentials.google_maps_api_key
    rescue StandardError
      nil
    end

    return nil if key.blank?

    details = GooglePlaces::PlaceDetails.new(api_key: key).fetch!(place_id)
    return nil unless details.is_a?(Hash)

    {
      'formatted_address' => details[:formatted_address],
      'international_phone_number' => details[:international_phone_number],
      'google_url' => details[:google_url],
      'types' => Array(details[:types]),
      'address_components' => Array(details[:address_components]),
      'location' => details[:location],
      'fetched_at' => Time.current.iso8601,
    }.compact
  rescue StandardError
    nil
  end
end
