# frozen_string_literal: true

require 'test_helper'

# Tests for the DomainRedirect Rack middleware.
#
# The middleware issues a 301 permanent redirect for any request arriving on
# www.mellow.menu, forwarding to the canonical naked domain with the full path
# and query string preserved. All other hosts pass through unmodified.
class DomainRedirectTest < ActionDispatch::IntegrationTest
  # ── www → naked redirects ──────────────────────────────────────────────────

  test 'GET / on www.mellow.menu redirects 301 to naked domain' do
    get 'http://www.mellow.menu/'
    assert_response :moved_permanently
    assert_equal 'https://mellow.menu/', response.headers['Location']
  end

  test 'nested path is preserved in redirect' do
    get 'http://www.mellow.menu/restaurants/1/menus/2'
    assert_response :moved_permanently
    assert_equal 'https://mellow.menu/restaurants/1/menus/2',
                 response.headers['Location']
  end

  test 'query string is preserved in redirect' do
    get 'http://www.mellow.menu/smartmenus/my-slug?table=3'
    assert_response :moved_permanently
    assert_equal 'https://mellow.menu/smartmenus/my-slug?table=3',
                 response.headers['Location']
  end

  test 'path and query string are both preserved together' do
    get 'http://www.mellow.menu/explore/ireland/dublin?page=2&lang=en'
    assert_response :moved_permanently
    assert_equal 'https://mellow.menu/explore/ireland/dublin?page=2&lang=en',
                 response.headers['Location']
  end

  test 'redirect response contains no Set-Cookie header' do
    get 'http://www.mellow.menu/'
    assert_nil response.headers['Set-Cookie']
  end

  test 'redirect response body is empty' do
    get 'http://www.mellow.menu/'
    assert_empty response.body
  end

  # ── naked domain passes through ────────────────────────────────────────────

  test 'GET / on mellow.menu returns 200 and is not redirected' do
    get 'http://mellow.menu/'
    # Should not be a redirect — passes through to Rails router
    assert_not_equal 301, response.status
    assert_nil response.headers['Location']
  end

  test 'GET /smartmenus path on naked domain is not redirected' do
    sm = smartmenus(:customer_menu)
    get "http://mellow.menu/t/#{sm.public_token}"
    assert_not_equal 301, response.status
    assert_nil response.headers['Location']
  end

  # ── no redirect loop ───────────────────────────────────────────────────────

  test 'naked domain request does not redirect to itself' do
    get 'http://mellow.menu/'
    assert_not_equal 'https://mellow.menu/', response.headers['Location']
  end
end
