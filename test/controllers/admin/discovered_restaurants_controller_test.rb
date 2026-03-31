# frozen_string_literal: true

require 'test_helper'

class Admin::DiscoveredRestaurantsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:super_admin)
    sign_in @user

    @dr = DiscoveredRestaurant.create!(
      name: 'Test Bistro',
      city_name: 'Dublin',
      google_place_id: 'ChIJtest123',
      status: :pending,
      website_url: 'https://testbistro.example.com',
      metadata: {},
    )
  end

  teardown do
    @dr&.destroy
  end

  # ---------------------------------------------------------------------------
  # Authentication / access control
  # ---------------------------------------------------------------------------

  test 'index: redirects unauthenticated user' do
    sign_out @user
    get admin_discovered_restaurants_path

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test 'index: redirects non-admin user' do
    regular_user = users(:two)
    sign_in regular_user
    get admin_discovered_restaurants_path

    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # GET index
  # ---------------------------------------------------------------------------

  test 'index: returns 200 for super_admin' do
    get admin_discovered_restaurants_path

    assert_response :ok
  end

  test 'index: filters by status' do
    get admin_discovered_restaurants_path, params: { status: 'pending' }

    assert_response :ok
  end

  test 'index: filters by city' do
    get admin_discovered_restaurants_path, params: { city: 'Dublin' }

    assert_response :ok
  end

  test 'index: sorts by city_name asc' do
    get admin_discovered_restaurants_path, params: { sort: 'city_name', direction: 'asc' }

    assert_response :ok
  end

  test 'index: respects per_page param' do
    get admin_discovered_restaurants_path, params: { per_page: 10, page: 1 }

    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # GET show
  # ---------------------------------------------------------------------------

  test 'show: returns 200 for a known discovered restaurant' do
    # Disable auto-enrichment by marking metadata as already run
    @dr.update!(metadata: {
      'website_deep_dive' => { 'status' => 'completed' },
      'web_menu_scrape' => { 'status' => 'completed' },
      'place_details' => { 'fetched_at' => 1.hour.ago.iso8601 },
    })

    get admin_discovered_restaurant_path(@dr)

    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # POST create
  # ---------------------------------------------------------------------------

  test 'create: creates a new discovered restaurant and redirects' do
    assert_difference 'DiscoveredRestaurant.count', 1 do
      post admin_discovered_restaurants_path,
        params: {
          discovered_restaurant: {
            website_url: 'https://newplace.example.com',
            name: 'New Place',
            city_name: 'Cork',
          },
        }
    end

    assert_response :redirect
    assert_match(/added/i, flash[:notice].to_s)
  end

  test 'create: redirects with alert when website_url is blank' do
    post admin_discovered_restaurants_path,
      params: {
        discovered_restaurant: {
          website_url: '',
          name: 'No URL',
          city_name: 'Cork',
        },
      }

    assert_redirected_to admin_discovered_restaurants_path
    assert_match(/URL is required/i, flash[:alert].to_s)
  end

  test 'create: auto-fills name from domain when name is blank' do
    post admin_discovered_restaurants_path,
      params: {
        discovered_restaurant: {
          website_url: 'https://galwayeat.example.com',
          name: '',
          city_name: 'Galway',
        },
      }

    assert_response :redirect
    dr = DiscoveredRestaurant.order(:id).last
    assert dr.name.present?
    dr.destroy
  end

  # ---------------------------------------------------------------------------
  # PATCH update
  # ---------------------------------------------------------------------------

  test 'update: updates name and redirects' do
    patch admin_discovered_restaurant_path(@dr),
      params: {
        discovered_restaurant: {
          name: 'Updated Bistro Name',
        },
      }

    assert_response :redirect
    assert_equal 'Updated Bistro Name', @dr.reload.name
  end

  # ---------------------------------------------------------------------------
  # PATCH approve / reject
  # ---------------------------------------------------------------------------

  test 'approve: sets status to approved and enqueues provisioning job' do
    assert_enqueued_with(job: ProvisionUnclaimedRestaurantJob) do
      patch approve_admin_discovered_restaurant_path(@dr)
    end

    assert_equal 'approved', @dr.reload.status
    assert_response :redirect
    assert_match(/approved/i, flash[:notice].to_s)
  end

  test 'reject: sets status to rejected and redirects' do
    patch reject_admin_discovered_restaurant_path(@dr)

    assert_equal 'rejected', @dr.reload.status
    assert_response :redirect
    assert_match(/rejected/i, flash[:notice].to_s)
  end

  # ---------------------------------------------------------------------------
  # POST deep_dive_website
  # ---------------------------------------------------------------------------

  test 'deep_dive_website: queues job and redirects' do
    assert_enqueued_with(job: DiscoveredRestaurantWebsiteDeepDiveJob) do
      post deep_dive_website_admin_discovered_restaurant_path(@dr)
    end

    assert_response :redirect
    assert_match(/queued/i, flash[:notice].to_s)
  end

  test 'deep_dive_website: redirects with alert when no website_url' do
    @dr.update_column(:website_url, nil)

    post deep_dive_website_admin_discovered_restaurant_path(@dr)

    assert_response :redirect
    assert_match(/No website URL/i, flash[:alert].to_s)
  end

  # ---------------------------------------------------------------------------
  # GET deep_dive_status
  # ---------------------------------------------------------------------------

  test 'deep_dive_status: returns JSON with status' do
    @dr.update!(metadata: { 'website_deep_dive' => { 'status' => 'completed' } })

    get deep_dive_status_admin_discovered_restaurant_path(@dr), as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 'completed', body['status']
  end

  # ---------------------------------------------------------------------------
  # POST scrape_web_menus
  # ---------------------------------------------------------------------------

  test 'scrape_web_menus: queues job and redirects' do
    assert_enqueued_with(job: DiscoveredRestaurantWebMenuScrapeJob) do
      post scrape_web_menus_admin_discovered_restaurant_path(@dr)
    end

    assert_response :redirect
    assert_match(/queued/i, flash[:notice].to_s)
  end

  # ---------------------------------------------------------------------------
  # GET web_menu_scrape_status
  # ---------------------------------------------------------------------------

  test 'web_menu_scrape_status: returns JSON status' do
    @dr.update!(metadata: { 'web_menu_scrape' => { 'status' => 'in_progress' } })

    get web_menu_scrape_status_admin_discovered_restaurant_path(@dr), as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 'in_progress', body['status']
  end

  # ---------------------------------------------------------------------------
  # GET place_details
  # ---------------------------------------------------------------------------

  test 'place_details: returns JSON with google_place_id and details' do
    get place_details_admin_discovered_restaurant_path(@dr), as: :json

    assert_response :ok
    body = response.parsed_body
    assert_equal 'ChIJtest123', body['google_place_id']
  end

  # ---------------------------------------------------------------------------
  # PATCH bulk_update
  # ---------------------------------------------------------------------------

  test 'bulk_update: sets status for given ids' do
    patch bulk_update_admin_discovered_restaurants_path,
      params: {
        discovered_restaurant_ids: [@dr.id],
        operation: 'set_status',
        value: 'rejected',
      }

    assert_redirected_to admin_discovered_restaurants_path
    assert_equal 'rejected', @dr.reload.status
  end

  test 'bulk_update: redirects with alert for invalid operation' do
    patch bulk_update_admin_discovered_restaurants_path,
      params: {
        discovered_restaurant_ids: [@dr.id],
        operation: 'unknown',
        value: 'something',
      }

    assert_redirected_to admin_discovered_restaurants_path
    assert_match(/Invalid bulk operation/i, flash[:alert].to_s)
  end

  test 'bulk_update: redirects with alert when ids blank' do
    patch bulk_update_admin_discovered_restaurants_path,
      params: { discovered_restaurant_ids: [], operation: '', value: '' }

    assert_redirected_to admin_discovered_restaurants_path
    assert_match(/Invalid bulk update/i, flash[:alert].to_s)
  end

  # ---------------------------------------------------------------------------
  # GET approved_imports
  # ---------------------------------------------------------------------------

  test 'approved_imports: returns 200' do
    get approved_imports_admin_discovered_restaurants_path

    assert_response :ok
  end

  # ---------------------------------------------------------------------------
  # POST resync_to_restaurant
  # ---------------------------------------------------------------------------

  test 'resync_to_restaurant: redirects with alert when no linked restaurant' do
    # @dr has no restaurant_id
    post resync_to_restaurant_admin_discovered_restaurant_path(@dr)

    assert_response :redirect
    assert_match(/No linked restaurant/i, flash[:alert].to_s)
  end

  # ---------------------------------------------------------------------------
  # POST refresh_place_details
  # ---------------------------------------------------------------------------

  test 'refresh_place_details: redirects with alert when google_maps key missing' do
    prev_key = ENV['GOOGLE_MAPS_API_KEY']
    ENV.delete('GOOGLE_MAPS_API_KEY')
    ENV.delete('GOOGLE_MAPS_BROWSER_API_KEY')

    Rails.application.credentials.stub(:google_maps_api_key, nil) do
      post refresh_place_details_admin_discovered_restaurant_path(@dr)
    end

    assert_response :redirect
    assert_match(/not configured/i, flash[:alert].to_s)
  ensure
    ENV['GOOGLE_MAPS_API_KEY'] = prev_key if prev_key
  end
end
