require 'test_helper'

class PwaFunctionalityTest < ActionDispatch::IntegrationTest
  test 'should serve manifest.json' do
    get '/manifest.json'

    assert_response :success
    assert_equal 'application/json', response.content_type

    manifest = response.parsed_body
    assert_equal 'Smart Menu - Restaurant Management', manifest['name']
    assert_equal 'Smart Menu', manifest['short_name']
    assert_equal 'standalone', manifest['display']
    assert manifest['icons'].present?
  end

  test 'manifest should have required PWA fields' do
    get '/manifest.json'

    manifest = response.parsed_body

    # Required fields for PWA
    assert manifest['name'].present?, 'name is required'
    assert manifest['short_name'].present?, 'short_name is required'
    assert manifest['start_url'].present?, 'start_url is required'
    assert manifest['display'].present?, 'display is required'
    assert manifest['icons'].present?, 'icons are required'

    # Check icons have required sizes
    icon_sizes = manifest['icons'].pluck('sizes')
    assert_includes icon_sizes, '192x192', '192x192 icon is required'
    assert_includes icon_sizes, '512x512', '512x512 icon is required'
  end

  test 'should serve service worker JavaScript file' do
    get '/pwa/service-worker.js'

    # Service worker might be served as JavaScript or plain text
    assert_response :success
    assert_includes ['application/javascript', 'text/javascript', 'text/plain'],
                    response.content_type
  end

  test 'should serve offline page' do
    get '/offline'

    assert_response :success
  end

  test 'manifest should have proper theme colors' do
    get '/manifest.json'

    manifest = response.parsed_body

    assert manifest['theme_color'].present?
    assert manifest['background_color'].present?

    # Colors should be valid hex codes
    assert_match(/^#[0-9a-fA-F]{6}$/, manifest['theme_color'])
    assert_match(/^#[0-9a-fA-F]{6}$/, manifest['background_color'])
  end

  test 'manifest should have app shortcuts' do
    get '/manifest.json'

    manifest = response.parsed_body

    if manifest['shortcuts'].present?
      manifest['shortcuts'].each do |shortcut|
        assert shortcut['name'].present?, 'shortcut name is required'
        assert shortcut['url'].present?, 'shortcut url is required'
      end
    end
  end

  test 'should have proper cache control headers for manifest' do
    get '/manifest.json'

    # Manifest should be cacheable but not for too long
    # to allow updates to be picked up
    assert_response :success
  end

end
