class CityDiscoveryJob < ApplicationJob
  queue_as :default

  def perform(city_query:, place_types:)
    city = city_query.to_s.strip
    return if city.blank?

    types = Array(place_types).map { |t| t.to_s.strip }.reject(&:blank?).uniq

    key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil) || ENV.fetch('GOOGLE_MAPS_BROWSER_API_KEY', nil)
    key ||= begin
      Rails.application.credentials.google_maps_api_key
    rescue StandardError
      nil
    end

    raise 'Google Places API key is not configured' if key.blank?

    GooglePlaces::CityDiscovery.new(api_key: key).discover!(city_query: city, place_types: types)
  end
end
