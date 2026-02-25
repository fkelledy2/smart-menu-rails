require 'test_helper'

class Admin::DiscoveredRestaurantsAutoEnrichTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    @user.update_columns(admin: true, super_admin: true) unless @user.admin? && @user.super_admin?
    sign_in @user

    @dr = DiscoveredRestaurant.create!(
      name: 'Auto Enrich Bistro',
      city_name: 'Dublin',
      google_place_id: 'ChIJauto123',
      status: :pending,
      website_url: 'https://example-auto.com',
      metadata: {},
    )
  end

  # ── Auto-trigger on first view ──

  test 'show auto-triggers all three enrichments when never run' do
    assert_enqueued_jobs 3 do
      get admin_discovered_restaurant_path(@dr)
    end

    assert_response :success

    @dr.reload
    meta = @dr.metadata

    assert_equal 'queued', meta.dig('website_deep_dive', 'status')
    assert meta.dig('website_deep_dive', 'auto_triggered'), 'deep dive should be marked auto_triggered'

    assert_equal 'queued', meta.dig('web_menu_scrape', 'status')
    assert meta.dig('web_menu_scrape', 'auto_triggered'), 'menu scrape should be marked auto_triggered'
  end

  test 'show does not re-trigger enrichments on subsequent views' do
    @dr.update!(metadata: {
      'place_details' => { 'fetched_at' => 1.hour.ago.iso8601 },
      'website_deep_dive' => { 'status' => 'completed', 'extracted_at' => 1.hour.ago.iso8601 },
      'web_menu_scrape' => { 'status' => 'completed', 'updated_at' => 1.hour.ago.iso8601 },
    })

    assert_no_enqueued_jobs do
      get admin_discovered_restaurant_path(@dr)
    end

    assert_response :success
  end

  test 'show does not trigger deep dive or menu scrape when no website URL' do
    @dr.update!(website_url: nil)

    # Should only enqueue the place details job (google_place_id is present)
    assert_enqueued_jobs 1 do
      get admin_discovered_restaurant_path(@dr)
    end

    assert_response :success

    @dr.reload
    assert_nil @dr.metadata.dig('website_deep_dive', 'status')
    assert_nil @dr.metadata.dig('web_menu_scrape', 'status')
  end

  test 'show does not trigger place details for manual google_place_id' do
    @dr.update!(google_place_id: 'manual_abc123', website_url: nil)

    assert_no_enqueued_jobs do
      get admin_discovered_restaurant_path(@dr)
    end

    assert_response :success
  end

  test 'show skips place details when already fetched but still triggers deep dive and scrape' do
    @dr.update!(metadata: {
      'place_details' => { 'fetched_at' => 1.hour.ago.iso8601 },
    })

    # Should enqueue deep dive + menu scrape (not place details)
    assert_enqueued_jobs 2 do
      get admin_discovered_restaurant_path(@dr)
    end

    assert_response :success
  end

  test 'show does not re-trigger queued enrichments' do
    @dr.update!(metadata: {
      'website_deep_dive' => { 'status' => 'queued' },
      'web_menu_scrape' => { 'status' => 'queued' },
    })

    # Should only enqueue place details (deep dive and scrape already queued)
    assert_enqueued_jobs 1 do
      get admin_discovered_restaurant_path(@dr)
    end

    assert_response :success
  end
end
