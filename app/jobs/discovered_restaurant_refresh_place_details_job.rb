# frozen_string_literal: true

class DiscoveredRestaurantRefreshPlaceDetailsJob < ApplicationJob
  queue_as :default

  def perform(discovered_restaurant_id:, triggered_by_user_id: nil)
    dr = DiscoveredRestaurant.find_by(id: discovered_restaurant_id)
    return if dr.nil?

    place_id = dr.google_place_id.to_s.strip
    return if place_id.blank? || place_id.start_with?('manual_')

    key = ENV.fetch('GOOGLE_MAPS_API_KEY', nil) || ENV.fetch('GOOGLE_MAPS_BROWSER_API_KEY', nil)
    key ||= begin
      Rails.application.credentials.google_maps_api_key
    rescue StandardError
      nil
    end
    return if key.blank?

    details = GooglePlaces::PlaceDetails.new(api_key: key).fetch!(place_id)
    return unless details.is_a?(Hash)

    fetched = {
      'formatted_address' => details[:formatted_address],
      'international_phone_number' => details[:international_phone_number],
      'google_url' => details[:google_url],
      'types' => Array(details[:types]),
      'address_components' => Array(details[:address_components]),
      'location' => details[:location],
      'opening_hours' => details[:opening_hours],
      'fetched_at' => Time.current.iso8601,
    }.compact

    metadata = dr.metadata.is_a?(Hash) ? dr.metadata : {}
    metadata['place_details'] = (metadata['place_details'].is_a?(Hash) ? metadata['place_details'] : {}).merge(fetched)
    dr.update!(metadata: metadata)

    Rails.logger.info "[RefreshPlaceDetailsJob] Updated place details for DR##{dr.id} (#{dr.name})"
  rescue StandardError => e
    Rails.logger.warn "[RefreshPlaceDetailsJob] Failed for DR##{discovered_restaurant_id}: #{e.message}"
  end
end
