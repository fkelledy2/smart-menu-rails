# frozen_string_literal: true

require 'test_helper'

class SeoExplorePagesTest < ActionDispatch::IntegrationTest
  setup do
    @city_page = ExplorePage.create!(
      country_slug: 'ireland',
      country_name: 'Ireland',
      city_slug: 'dublin',
      city_name: 'Dublin',
      restaurant_count: 5,
      published: true,
      last_refreshed_at: Time.current,
    )
    @category_page = ExplorePage.create!(
      country_slug: 'ireland',
      country_name: 'Ireland',
      city_slug: 'dublin',
      city_name: 'Dublin',
      category_slug: 'italian',
      category_name: 'Italian',
      restaurant_count: 3,
      published: true,
      last_refreshed_at: Time.current,
    )
  end

  # ── Explore index ────────────────────────────────────────────────────────

  test 'explore index returns 200' do
    get explore_index_path
    assert_response :success
  end

  # ── Explore country ──────────────────────────────────────────────────────

  test 'explore country returns 200 for valid country' do
    get explore_country_path(country: 'ireland')
    assert_response :success
  end

  test 'explore country returns 404 for unknown country' do
    get explore_country_path(country: 'narnia')
    assert_response :not_found
  end

  # ── Explore city ─────────────────────────────────────────────────────────

  test 'explore city returns 200 for valid city page' do
    get explore_city_path(country: 'ireland', city: 'dublin')
    assert_response :success
  end

  test 'explore city includes JSON-LD ItemList' do
    get explore_city_path(country: 'ireland', city: 'dublin')
    assert_match 'application/ld+json', response.body
    json_ld = extract_json_ld(response.body)
    assert_equal 'ItemList', json_ld['@type']
  end

  test 'explore city has dynamic meta tags' do
    get explore_city_path(country: 'ireland', city: 'dublin')
    assert_select 'meta[property="og:title"]' do |tags|
      assert_match(/Dublin/, tags.first['content'])
    end
    assert_select 'link[rel="canonical"]' do |tags|
      assert_match %r{/explore/ireland/dublin}, tags.first['href']
    end
  end

  test 'explore city returns 404 for unpublished page' do
    @city_page.update!(published: false)
    get explore_city_path(country: 'ireland', city: 'dublin')
    assert_response :not_found
  end

  # ── Explore category ─────────────────────────────────────────────────────

  test 'explore category returns 200 for valid category page' do
    get explore_category_path(country: 'ireland', city: 'dublin', category: 'italian')
    assert_response :success
  end

  test 'explore category includes JSON-LD' do
    get explore_category_path(country: 'ireland', city: 'dublin', category: 'italian')
    json_ld = extract_json_ld(response.body)
    assert_equal 'ItemList', json_ld['@type']
    assert_match(/Italian/, json_ld['name'])
  end

  test 'explore category returns 404 for invalid category' do
    get explore_category_path(country: 'ireland', city: 'dublin', category: 'martian-food')
    assert_response :not_found
  end

  private

  def extract_json_ld(html)
    match = html.match(/<script type="application\/ld\+json">\s*(.+?)\s*<\/script>/m)
    assert match, 'Expected JSON-LD script block in response'
    JSON.parse(match[1])
  end
end
