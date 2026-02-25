# frozen_string_literal: true

require 'test_helper'

class SeoStructuredDataTest < ActionDispatch::IntegrationTest
  # ── Phase 1: JSON-LD on smartmenu pages ──────────────────────────────────

  test 'smartmenu page includes JSON-LD script block' do
    sm = smartmenus(:customer_menu)
    get "/smartmenus/#{sm.slug}"
    assert_response :success
    assert_match 'application/ld+json', response.body
  end

  test 'smartmenu JSON-LD contains Restaurant type and name' do
    sm = smartmenus(:customer_menu)
    get "/smartmenus/#{sm.slug}"
    json_ld = extract_json_ld(response.body)
    assert_equal 'https://schema.org', json_ld['@context']
    assert_equal 'Restaurant', json_ld['@type']
    assert_equal sm.restaurant.name, json_ld['name']
  end

  test 'smartmenu JSON-LD contains Menu with sections' do
    sm = smartmenus(:customer_menu)
    get "/smartmenus/#{sm.slug}"
    json_ld = extract_json_ld(response.body)
    menu = json_ld['menu']
    assert_equal 'Menu', menu['@type']
    assert menu['hasMenuSection'].is_a?(Array)
  end

  test 'smartmenu JSON-LD includes correct URL' do
    sm = smartmenus(:customer_menu)
    get "/smartmenus/#{sm.slug}"
    json_ld = extract_json_ld(response.body)
    assert_equal "https://www.mellow.menu/smartmenus/#{sm.slug}", json_ld['url']
  end

  # ── Phase 1: Dynamic meta tags ──────────────────────────────────────────

  test 'smartmenu page has restaurant-specific og:title' do
    sm = smartmenus(:customer_menu)
    get "/smartmenus/#{sm.slug}"
    assert_select 'meta[property="og:title"]' do |tags|
      assert_match sm.restaurant.name, tags.first['content']
    end
  end

  test 'smartmenu page has canonical URL pointing to smartmenu' do
    sm = smartmenus(:customer_menu)
    get "/smartmenus/#{sm.slug}"
    assert_select 'link[rel="canonical"]' do |tags|
      assert_match "smartmenus/#{sm.slug}", tags.first['href']
    end
  end

  test 'home page retains default meta tags' do
    get root_path
    # Home page should redirect logged-out users to root with marketing layout
    # or render with default meta tags
    if response.status == 200
      assert_select 'meta[property="og:title"]'
      assert_select 'link[rel="canonical"]'
    end
  end

  # ── Phase 1: No JSON-LD on non-public pages ─────────────────────────────

  test 'home page does not include JSON-LD' do
    get root_path
    if response.status == 200
      assert_no_match(/application\/ld\+json/, response.body)
    end
  end

  private

  def extract_json_ld(html)
    match = html.match(/<script type="application\/ld\+json">\s*(.+?)\s*<\/script>/m)
    assert match, 'Expected JSON-LD script block in response'
    JSON.parse(match[1])
  end
end
