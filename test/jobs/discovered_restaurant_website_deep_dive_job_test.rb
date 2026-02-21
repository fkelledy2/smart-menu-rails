require 'test_helper'

class DiscoveredRestaurantWebsiteDeepDiveJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @dr = DiscoveredRestaurant.create!(
      name: 'Test Bistro',
      city_name: 'Dublin',
      google_place_id: 'ChIJfake123',
      status: :pending,
      website_url: 'https://example-bistro.com',
      metadata: {},
    )
  end

  # --- helpers ---

  def base_website_result(overrides = {})
    {
      'source_base_url' => 'https://example-bistro.com',
      'visited_urls' => ['https://example-bistro.com/'],
      'emails' => [],
      'phones' => [],
      'address_candidates' => [],
      'context_types' => [],
      'social_links' => [],
      'about' => nil,
      'homepage_text' => nil,
      'extracted_at' => Time.current.iso8601,
    }.merge(overrides)
  end

  def fake_extractor(result)
    ext = Object.new
    ext.define_singleton_method(:extract) { result }
    ext
  end

  def fake_generator(return_value)
    gen = Object.new
    gen.define_singleton_method(:generate) { |**_kwargs| return_value }
    gen
  end

  def run_job(website_result:, place_details: nil, ai_description: nil)
    ext = fake_extractor(website_result)
    gen = fake_generator(ai_description)
    pd  = place_details

    ext_new = ->(*_args, **_kw) { ext }
    gen_new = ->(*_args, **_kw) { gen }

    MenuDiscovery::WebsiteContactExtractor.stub(:new, ext_new) do
      MenuDiscovery::RestaurantDescriptionGenerator.stub(:new, gen_new) do
        DiscoveredRestaurantWebsiteDeepDiveJob.define_method(:fetch_place_details) { |_dr| pd }
        begin
          DiscoveredRestaurantWebsiteDeepDiveJob.perform_now(discovered_restaurant_id: @dr.id)
        ensure
          DiscoveredRestaurantWebsiteDeepDiveJob.remove_method(:fetch_place_details)
        end
      end
    end

    @dr.reload
  end

  # =============================================================
  # Description population tests
  # =============================================================

  test 'description is set from AI when about page text is found' do
    run_job(
      website_result: base_website_result(
        'about' => { 'url' => 'https://example-bistro.com/about', 'text' => 'We are a family-run French bistro serving classic dishes since 1985.' },
      ),
      ai_description: 'A family-run French bistro offering classic dishes rooted in decades of tradition.',
    )

    assert_equal 'A family-run French bistro offering classic dishes rooted in decades of tradition.', @dr.description
    assert_equal 'ai_generated', @dr.metadata.dig('field_sources', 'description', 'source')
  end

  test 'description falls back to raw about text when AI is unavailable' do
    run_job(
      website_result: base_website_result(
        'about' => { 'url' => 'https://example-bistro.com/about', 'text' => 'We are a family-run French bistro.' },
      ),
      ai_description: nil,
    )

    assert_equal 'We are a family-run French bistro.', @dr.description
    assert_equal 'website_about', @dr.metadata.dig('field_sources', 'description', 'source')
  end

  test 'description uses homepage text when no about page is found' do
    run_job(
      website_result: base_website_result('homepage_text' => 'Welcome to Test Bistro. Seasonal Irish cooking.'),
      ai_description: nil,
    )

    assert_equal 'Welcome to Test Bistro. Seasonal Irish cooking.', @dr.description
    assert_equal 'website_homepage', @dr.metadata.dig('field_sources', 'description', 'source')
  end

  test 'description is AI-generated from homepage text when no about page exists' do
    run_job(
      website_result: base_website_result('homepage_text' => 'Welcome to Test Bistro. Seasonal Irish cooking.'),
      ai_description: 'Seasonal Irish cooking served in a warm Dublin setting.',
    )

    assert_equal 'Seasonal Irish cooking served in a warm Dublin setting.', @dr.description
    assert_equal 'ai_generated', @dr.metadata.dig('field_sources', 'description', 'source')
  end

  test 'description is AI-generated from name alone when no page text is available' do
    run_job(
      website_result: base_website_result,
      ai_description: 'A contemporary Dublin bistro with a focus on locally sourced ingredients.',
    )

    assert_equal 'A contemporary Dublin bistro with a focus on locally sourced ingredients.', @dr.description
    assert_equal 'ai_generated', @dr.metadata.dig('field_sources', 'description', 'source')
  end

  test 'description is overwritten on re-enrich even when previously set' do
    @dr.update!(description: 'Old manually written description', metadata: {
      'field_sources' => { 'description' => { 'source' => 'manual', 'updated_at' => 1.day.ago.iso8601 } },
    },)

    run_job(
      website_result: base_website_result(
        'about' => { 'url' => 'https://example-bistro.com/about', 'text' => 'Fresh about text.' },
      ),
      ai_description: 'A refreshed AI description.',
    )

    assert_equal 'A refreshed AI description.', @dr.description, 'Description should be overwritten on re-enrich'
    assert_equal 'ai_generated', @dr.metadata.dig('field_sources', 'description', 'source')
  end

  test 'description is left nil when no text and AI returns nil' do
    run_job(
      website_result: base_website_result,
      ai_description: nil,
    )

    assert_nil @dr.description
    assert_nil @dr.metadata.dig('field_sources', 'description')
  end

  # =============================================================
  # Field source tracking tests
  # =============================================================

  test 'field_sources tracks establishment_types from google and website' do
    run_job(
      website_result: base_website_result('context_types' => ['bar']),
      place_details: {
        'types' => %w[restaurant food],
        'address_components' => [],
        'location' => {},
      },
      ai_description: nil,
    )

    fs = @dr.metadata.dig('field_sources', 'establishment_types')
    assert fs.present?, 'establishment_types should have field_sources'
    assert_includes fs['source'], 'google_places'
    assert_includes fs['source'], 'website'
  end

  test 'field_sources tracks address fields from google places' do
    run_job(
      website_result: base_website_result,
      place_details: {
        'types' => [],
        'address_components' => [
          { 'types' => ['country'], 'short_name' => 'IE' },
          { 'types' => ['postal_code'], 'long_name' => 'D02' },
          { 'types' => ['locality'], 'long_name' => 'Dublin' },
          { 'types' => ['administrative_area_level_1'], 'short_name' => 'L' },
        ],
        'location' => {},
      },
      ai_description: nil,
    )

    %w[country_code postcode city state].each do |field|
      fs = @dr.metadata.dig('field_sources', field)
      assert fs.present?, "#{field} should have field_sources"
      assert_equal 'google_places', fs['source'], "#{field} source should be google_places"
    end
  end

  # =============================================================
  # Address resolution fallback tests
  # =============================================================

  test 'resolves postcode and country via Google Places when address is scraped but components missing' do
    fake_resolved = {
      'place_id' => 'ChIJresolved1',
      'formatted_address' => '42 Grafton Street, Dublin, D02 XY45, Ireland',
      'address_components' => [
        { 'types' => ['street_number'], 'long_name' => '42' },
        { 'types' => ['route'], 'long_name' => 'Grafton Street' },
        { 'types' => ['locality'], 'long_name' => 'Dublin' },
        { 'types' => ['administrative_area_level_1'], 'short_name' => 'L' },
        { 'types' => ['postal_code'], 'long_name' => 'D02 XY45' },
        { 'types' => ['country'], 'short_name' => 'IE' },
      ],
      'resolved_at' => Time.current.iso8601,
    }

    ext = fake_extractor(base_website_result('address_candidates' => ['42 Grafton Street, Dublin']))
    gen = fake_generator(nil)

    ext_new = ->(*_args, **_kw) { ext }
    gen_new = ->(*_args, **_kw) { gen }

    MenuDiscovery::WebsiteContactExtractor.stub(:new, ext_new) do
      MenuDiscovery::RestaurantDescriptionGenerator.stub(:new, gen_new) do
        DiscoveredRestaurantWebsiteDeepDiveJob.define_method(:fetch_place_details) { |_dr| nil }
        DiscoveredRestaurantWebsiteDeepDiveJob.define_method(:resolve_address_via_google) { |_addr, _name| fake_resolved }
        begin
          DiscoveredRestaurantWebsiteDeepDiveJob.perform_now(discovered_restaurant_id: @dr.id)
        ensure
          DiscoveredRestaurantWebsiteDeepDiveJob.remove_method(:fetch_place_details)
          DiscoveredRestaurantWebsiteDeepDiveJob.remove_method(:resolve_address_via_google)
        end
      end
    end

    @dr.reload
    assert_equal '42 Grafton Street, Dublin', @dr.address1
    assert_equal 'D02 XY45', @dr.postcode
    assert_equal 'IE', @dr.country_code
    assert_equal 'Dublin', @dr.city
    assert_equal 'L', @dr.state

    assert_equal 'website', @dr.metadata.dig('field_sources', 'address1', 'source')
    assert_equal 'google_places_address_resolve', @dr.metadata.dig('field_sources', 'postcode', 'source')
    assert_equal 'google_places_address_resolve', @dr.metadata.dig('field_sources', 'country_code', 'source')

    assert_equal 'ChIJresolved1', @dr.metadata.dig('address_resolution', 'resolved_place_id')
  end

  test 'skips address resolution when postcode and country already present from google_places' do
    run_job(
      website_result: base_website_result('address_candidates' => ['42 Grafton Street']),
      place_details: {
        'types' => [],
        'address_components' => [
          { 'types' => ['postal_code'], 'long_name' => 'D02' },
          { 'types' => ['country'], 'short_name' => 'IE' },
        ],
        'location' => {},
      },
      ai_description: nil,
    )

    assert_equal 'D02', @dr.postcode
    assert_equal 'IE', @dr.country_code
    assert_equal 'google_places', @dr.metadata.dig('field_sources', 'postcode', 'source')
    assert_equal 'google_places', @dr.metadata.dig('field_sources', 'country_code', 'source')
    assert_nil @dr.metadata['address_resolution'], 'Should not resolve if already filled by place_details'
  end

  test 'address resolution handles nil gracefully' do
    ext = fake_extractor(base_website_result('address_candidates' => ['Some address']))
    gen = fake_generator(nil)

    ext_new = ->(*_args, **_kw) { ext }
    gen_new = ->(*_args, **_kw) { gen }

    MenuDiscovery::WebsiteContactExtractor.stub(:new, ext_new) do
      MenuDiscovery::RestaurantDescriptionGenerator.stub(:new, gen_new) do
        DiscoveredRestaurantWebsiteDeepDiveJob.define_method(:fetch_place_details) { |_dr| nil }
        DiscoveredRestaurantWebsiteDeepDiveJob.define_method(:resolve_address_via_google) { |_addr, _name| nil }
        begin
          DiscoveredRestaurantWebsiteDeepDiveJob.perform_now(discovered_restaurant_id: @dr.id)
        ensure
          DiscoveredRestaurantWebsiteDeepDiveJob.remove_method(:fetch_place_details)
          DiscoveredRestaurantWebsiteDeepDiveJob.remove_method(:resolve_address_via_google)
        end
      end
    end

    @dr.reload
    assert_equal 'Some address', @dr.address1
    assert_nil @dr.postcode
    assert_nil @dr.country_code
    assert_nil @dr.metadata['address_resolution']
  end

  test 'deep dive status is completed after successful run' do
    run_job(
      website_result: base_website_result,
      ai_description: nil,
    )

    assert_equal 'completed', @dr.metadata.dig('website_deep_dive', 'status')
  end
end
