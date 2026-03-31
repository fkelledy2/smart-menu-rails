# frozen_string_literal: true

require 'test_helper'

class DiscoveredRestaurantRefreshPlaceDetailsJobTest < ActiveSupport::TestCase
  # DiscoveredRestaurantRefreshPlaceDetailsJob fetches Google Places data and updates
  # the DiscoveredRestaurant metadata. Tests use dynamic record creation (no fixture).

  def setup
    @dr = DiscoveredRestaurant.create!(
      name: 'Test Restaurant',
      google_place_id: 'ChIJ_test_place_id',
      city_name: 'Dublin',
      status: 'pending',
    )
  end

  def teardown
    @dr&.destroy! if @dr&.persisted?
  end

  test 'perform is a no-op when discovered restaurant does not exist' do
    assert_nothing_raised do
      DiscoveredRestaurantRefreshPlaceDetailsJob.new.perform(
        discovered_restaurant_id: -999,
      )
    end
  end

  test 'perform is a no-op when google_place_id is blank' do
    # Use update_column to bypass the presence validation for this edge-case test
    @dr.update_column(:google_place_id, '')

    google_called = false
    GooglePlaces::PlaceDetails.stub(:new, ->(_args) { google_called = true; nil }) do
      DiscoveredRestaurantRefreshPlaceDetailsJob.new.perform(
        discovered_restaurant_id: @dr.id,
      )
    end

    assert_not google_called, 'PlaceDetails should not be called with blank place_id'
  end

  test 'perform is a no-op when place_id starts with manual_' do
    @dr.update!(google_place_id: 'manual_abc123')

    google_called = false
    GooglePlaces::PlaceDetails.stub(:new, ->(_args) { google_called = true; nil }) do
      DiscoveredRestaurantRefreshPlaceDetailsJob.new.perform(
        discovered_restaurant_id: @dr.id,
      )
    end

    assert_not google_called, 'PlaceDetails should not be called for manual_ place IDs'
  end

  test 'perform updates metadata when place details are fetched successfully' do
    fake_details = {
      formatted_address: '123 Test St',
      international_phone_number: '+1-555-0100',
      google_url: 'https://maps.google.com/test',
      types: ['restaurant'],
      address_components: [],
      location: { lat: 53.3, lng: -6.2 },
      opening_hours: { weekday_text: [] },
    }

    fake_fetcher = Object.new
    fake_fetcher.define_singleton_method(:fetch!) { |_place_id| fake_details }

    GooglePlaces::PlaceDetails.stub(:new, ->(api_key:) { fake_fetcher }) do
      DiscoveredRestaurantRefreshPlaceDetailsJob.new.perform(
        discovered_restaurant_id: @dr.id,
        triggered_by_user_id: nil,
      )
    end

    @dr.reload
    place_details = @dr.metadata&.dig('place_details')
    assert place_details.present?, 'metadata place_details should be set'
    assert_equal '123 Test St', place_details['formatted_address']
  end

  test 'perform handles StandardError gracefully without raising' do
    GooglePlaces::PlaceDetails.stub(:new, ->(_args) { raise StandardError, 'API error' }) do
      assert_nothing_raised do
        DiscoveredRestaurantRefreshPlaceDetailsJob.new.perform(
          discovered_restaurant_id: @dr.id,
        )
      end
    end
  end
end
