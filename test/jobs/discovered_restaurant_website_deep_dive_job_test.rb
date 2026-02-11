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
    })

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
        'types' => ['restaurant', 'food'],
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

  test 'deep dive status is completed after successful run' do
    run_job(
      website_result: base_website_result,
      ai_description: nil,
    )

    assert_equal 'completed', @dr.metadata.dig('website_deep_dive', 'status')
  end
end
