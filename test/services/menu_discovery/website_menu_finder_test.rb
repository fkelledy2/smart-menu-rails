require 'test_helper'

class MenuDiscovery::WebsiteMenuFinderTest < ActiveSupport::TestCase
  # Stub HTTP client that returns pre-configured responses per URL
  class FakeHttp
    def initialize(responses = {})
      @responses = responses
    end

    def get(url, **_opts)
      resp = @responses[url]
      return FakeResponse.new(404, '', {}) if resp.nil?

      FakeResponse.new(resp[:code] || 200, resp[:body] || '', resp[:headers] || { 'content-type' => 'text/html' })
    end
  end

  class FakeResponse
    attr_reader :code, :body, :headers

    def initialize(code, body, headers)
      @code = code
      @body = body
      @headers = headers
    end
  end

  class AllowAllRobots
    def allowed?(_url) = true
    def evidence(_url) = {}
  end

  def make_page(title:, links: [], prices: 0)
    price_html = (1..prices).map { |i| "<p>Item #{i} - €#{10 + i}.00</p>" }.join
    link_html = links.map do |link|
      if link.is_a?(Hash)
        "<a href=\"#{link[:href]}\">#{link[:text] || 'link'}</a>"
      else
        "<a href=\"#{link}\">link</a>"
      end
    end.join
    "<html><head><title>#{title}</title></head><body>#{price_html}#{link_html}</body></html>"
  end

  test 'find_menus returns both pdfs and html_menu_pages' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: ['https://example.com/menu', 'https://example.com/menu.pdf']),
      },
      'https://example.com/menu' => {
        body: make_page(title: 'Menu', prices: 5),
      },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    result = finder.find_menus
    assert_includes result[:pdfs], 'https://example.com/menu.pdf'
    assert_equal 1, result[:html_menu_pages].size
    assert_equal 'https://example.com/menu', result[:html_menu_pages].first[:url]
  end

  test 'find_menu_pdfs returns only PDFs for backward compatibility' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: ['https://example.com/menu.pdf']),
      },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    pdfs = finder.find_menu_pdfs
    assert_kind_of Array, pdfs
    assert_includes pdfs, 'https://example.com/menu.pdf'
  end

  test 'finds pages with food and drink in path' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: ['https://example.com/food', 'https://example.com/drink-list']),
      },
      'https://example.com/food' => {
        body: make_page(title: 'Food', prices: 4),
      },
      'https://example.com/drink-list' => {
        body: make_page(title: 'Drinks', prices: 4),
      },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    result = finder.find_menus
    urls = result[:html_menu_pages].pluck(:url)
    assert_includes urls, 'https://example.com/food'
    assert_includes urls, 'https://example.com/drink-list'
  end

  test 'skips pages without menu content (no prices)' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: ['https://example.com/menu']),
      },
      'https://example.com/menu' => {
        body: '<html><body><p>Our menu is coming soon!</p></body></html>',
      },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    result = finder.find_menus
    assert_empty result[:html_menu_pages]
  end

  test 'discovers menu pages via intermediate landing pages (depth 2)' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: [
          { href: 'https://example.com/lunch-brunch/', text: 'Lunch & Brunch' },
          { href: 'https://example.com/bistrot/', text: 'Bistrot' },
        ],),
      },
      'https://example.com/lunch-brunch' => {
        body: make_page(title: 'Lunch', links: [
          { href: 'https://example.com/menu_food_lunch/', text: 'See our menu' },
        ],),
      },
      'https://example.com/bistrot' => {
        body: make_page(title: 'Bistrot', links: [
          { href: 'https://example.com/bistrot/carta/', text: 'La Carta' },
        ],),
      },
      'https://example.com/menu_food_lunch' => {
        body: make_page(title: 'Lunch Menu', prices: 8),
      },
      'https://example.com/bistrot/carta' => {
        body: make_page(title: 'Carta', prices: 6),
      },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    result = finder.find_menus
    urls = result[:html_menu_pages].pluck(:url)
    assert_includes urls, 'https://example.com/menu_food_lunch'
    assert_includes urls, 'https://example.com/bistrot/carta'
  end

  test 'scores links by anchor text (menu-related text gets priority)' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: [
          { href: 'https://example.com/about/', text: 'About Us' },
          { href: 'https://example.com/caffetteria/', text: 'Caffetteria' },
          { href: 'https://example.com/events/', text: 'Events' },
        ],),
      },
      'https://example.com/about' => {
        body: '<html><body><p>About our restaurant</p></body></html>',
      },
      'https://example.com/caffetteria' => {
        body: make_page(title: 'Caffetteria', prices: 5),
      },
      'https://example.com/events' => {
        body: '<html><body><p>Upcoming events</p></body></html>',
      },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    result = finder.find_menus
    urls = result[:html_menu_pages].pluck(:url)
    assert_includes urls, 'https://example.com/caffetteria'
  end

  test 'discovers pages with multilingual path keywords (brunch, cocktail, bistrot)' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: [
          'https://example.com/brunch/',
          'https://example.com/cocktail-bar/',
        ],),
      },
      'https://example.com/brunch' => {
        body: make_page(title: 'Brunch', prices: 4),
      },
      'https://example.com/cocktail-bar' => {
        body: make_page(title: 'Cocktails', prices: 6),
      },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    result = finder.find_menus
    urls = result[:html_menu_pages].pluck(:url)
    assert_includes urls, 'https://example.com/brunch'
    assert_includes urls, 'https://example.com/cocktail-bar'
  end

  test 'respects max_pages limit' do
    http = FakeHttp.new(
      'https://example.com' => {
        body: make_page(title: 'Home', links: ['https://example.com/menu', 'https://example.com/menu2', 'https://example.com/menu3']),
      },
      'https://example.com/menu' => { body: make_page(title: 'Menu 1', prices: 5) },
      'https://example.com/menu2' => { body: make_page(title: 'Menu 2', prices: 5) },
      'https://example.com/menu3' => { body: make_page(title: 'Menu 3', prices: 5) },
    )

    finder = MenuDiscovery::WebsiteMenuFinder.new(
      base_url: 'https://example.com',
      http_client: http,
      robots_checker: AllowAllRobots.new,
    )

    result = finder.find_menus(max_pages: 2)
    # Should visit at most 2 pages total (home + 1 menu page)
    assert result[:html_menu_pages].size <= 2
  end
end
