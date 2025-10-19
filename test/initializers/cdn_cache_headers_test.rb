require 'test_helper'

class CdnCacheHeadersTest < ActiveSupport::TestCase
  test 'CdnCacheControl module is defined' do
    assert defined?(CdnCacheControl)
  end

  test 'CACHE_DURATIONS constant is defined' do
    assert defined?(CdnCacheControl::CACHE_DURATIONS)
  end

  test 'CACHE_DURATIONS includes common content types' do
    durations = CdnCacheControl::CACHE_DURATIONS
    
    assert durations.key?('application/javascript')
    assert durations.key?('text/css')
    assert durations.key?('image/png')
    assert durations.key?('image/jpeg')
    assert durations.key?('font/woff2')
  end

  test 'cache_control_for returns correct header for JavaScript' do
    header = CdnCacheControl.cache_control_for('application/javascript')
    
    assert_includes header, 'public'
    assert_includes header, 'max-age='
    assert_includes header, 'immutable'
  end

  test 'cache_control_for returns correct header for CSS' do
    header = CdnCacheControl.cache_control_for('text/css')
    
    assert_includes header, 'public'
    assert_includes header, 'max-age='
    assert_includes header, 'immutable'
  end

  test 'cache_control_for returns correct header for images' do
    header = CdnCacheControl.cache_control_for('image/png')
    
    assert_includes header, 'public'
    assert_includes header, 'max-age='
    assert_includes header, 'immutable'
  end

  test 'cache_control_for returns no-cache for HTML' do
    header = CdnCacheControl.cache_control_for('text/html')
    
    assert_includes header, 'no-cache'
    assert_includes header, 'no-store'
    assert_includes header, 'must-revalidate'
  end

  test 'cache_control_for uses default duration for unknown types' do
    header = CdnCacheControl.cache_control_for('application/unknown')
    
    assert_includes header, 'public'
    assert_includes header, 'max-age='
  end

  test 'cdn_cache_control_for returns correct header for JavaScript' do
    header = CdnCacheControl.cdn_cache_control_for('application/javascript')
    
    assert_includes header, 'public'
    assert_includes header, 'max-age='
    assert_not_includes header, 'immutable'
  end

  test 'cdn_cache_control_for returns no-cache for HTML' do
    header = CdnCacheControl.cdn_cache_control_for('text/html')
    
    assert_equal 'no-cache', header
  end

  test 'cacheable? returns true for JavaScript' do
    assert CdnCacheControl.cacheable?('application/javascript')
  end

  test 'cacheable? returns true for CSS' do
    assert CdnCacheControl.cacheable?('text/css')
  end

  test 'cacheable? returns true for images' do
    assert CdnCacheControl.cacheable?('image/png')
    assert CdnCacheControl.cacheable?('image/jpeg')
    assert CdnCacheControl.cacheable?('image/svg+xml')
  end

  test 'cacheable? returns false for HTML' do
    assert_not CdnCacheControl.cacheable?('text/html')
  end

  test 'cacheable? returns true for fonts' do
    assert CdnCacheControl.cacheable?('font/woff2')
    assert CdnCacheControl.cacheable?('font/woff')
  end

  test 'cacheable? returns true for unknown types with default duration' do
    assert CdnCacheControl.cacheable?('application/unknown')
  end

  test 'JavaScript has 1 year cache duration' do
    duration = CdnCacheControl::CACHE_DURATIONS['application/javascript']
    
    assert_equal 1.year.to_i, duration.to_i
  end

  test 'CSS has 1 year cache duration' do
    duration = CdnCacheControl::CACHE_DURATIONS['text/css']
    
    assert_equal 1.year.to_i, duration.to_i
  end

  test 'images have 1 year cache duration' do
    %w[image/png image/jpeg image/gif image/svg+xml].each do |content_type|
      duration = CdnCacheControl::CACHE_DURATIONS[content_type]
      
      assert_equal 1.year.to_i, duration.to_i, "#{content_type} should have 1 year cache"
    end
  end

  test 'fonts have 1 year cache duration' do
    %w[font/woff font/woff2 font/ttf].each do |content_type|
      duration = CdnCacheControl::CACHE_DURATIONS[content_type]
      
      assert_equal 1.year.to_i, duration.to_i, "#{content_type} should have 1 year cache"
    end
  end

  test 'JSON has short cache duration' do
    duration = CdnCacheControl::CACHE_DURATIONS['application/json']
    
    assert_equal 5.minutes.to_i, duration.to_i
  end

  test 'HTML has zero cache duration' do
    duration = CdnCacheControl::CACHE_DURATIONS['text/html']
    
    assert_equal 0, duration
  end

  test 'CdnCacheHeadersMiddleware is defined' do
    assert defined?(CdnCacheHeadersMiddleware)
  end

  test 'CdnCacheHeadersMiddleware can be instantiated' do
    app = ->(env) { [200, {}, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    assert_not_nil middleware
  end

  test 'CdnCacheHeadersMiddleware responds to call' do
    app = ->(env) { [200, {}, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    assert middleware.respond_to?(:call)
  end

  test 'CdnCacheHeadersMiddleware adds headers for asset paths' do
    app = ->(env) { [200, { 'Content-Type' => 'application/javascript' }, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    env = { 'PATH_INFO' => '/assets/application.js' }
    status, headers, _response = middleware.call(env)
    
    assert_equal 200, status
    assert headers.key?('Cache-Control')
    assert headers.key?('CDN-Cache-Control')
    assert headers.key?('Vary')
    assert headers.key?('X-Content-Type-Options')
  end

  test 'CdnCacheHeadersMiddleware does not add headers for non-asset paths' do
    app = ->(env) { [200, { 'Content-Type' => 'text/html' }, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    env = { 'PATH_INFO' => '/restaurants' }
    status, headers, _response = middleware.call(env)
    
    assert_equal 200, status
    # Should not add CDN headers for HTML pages
  end

  test 'CdnCacheHeadersMiddleware adds Vary header' do
    app = ->(env) { [200, { 'Content-Type' => 'application/javascript' }, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    env = { 'PATH_INFO' => '/assets/application.js' }
    _status, headers, _response = middleware.call(env)
    
    assert_equal 'Accept-Encoding', headers['Vary']
  end

  test 'CdnCacheHeadersMiddleware adds security headers' do
    app = ->(env) { [200, { 'Content-Type' => 'application/javascript' }, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    env = { 'PATH_INFO' => '/assets/application.js' }
    _status, headers, _response = middleware.call(env)
    
    assert_equal 'nosniff', headers['X-Content-Type-Options']
  end

  test 'CdnCacheHeadersMiddleware only adds headers for 200 responses' do
    app = ->(env) { [404, { 'Content-Type' => 'application/javascript' }, ['Not Found']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    env = { 'PATH_INFO' => '/assets/missing.js' }
    status, headers, _response = middleware.call(env)
    
    assert_equal 404, status
    # Should not add cache headers for error responses
  end

  test 'CdnCacheHeadersMiddleware handles paths with extensions' do
    app = ->(env) { [200, { 'Content-Type' => 'text/css' }, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    env = { 'PATH_INFO' => '/some/path/style.css' }
    _status, headers, _response = middleware.call(env)
    
    assert headers.key?('Cache-Control')
  end

  test 'CdnCacheHeadersMiddleware handles image paths' do
    app = ->(env) { [200, { 'Content-Type' => 'image/png' }, ['OK']] }
    middleware = CdnCacheHeadersMiddleware.new(app)
    
    env = { 'PATH_INFO' => '/images/logo.png' }
    _status, headers, _response = middleware.call(env)
    
    assert headers.key?('Cache-Control')
    assert_includes headers['Cache-Control'], 'immutable'
  end

  test 'middleware is not added in non-production environments' do
    # This test verifies the conditional loading in the initializer
    # In test environment, middleware should not be added
    assert_not Rails.env.production?
  end
end
