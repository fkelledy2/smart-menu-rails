# frozen_string_literal: true

require 'test_helper'

class BrowserCacheServiceTest < ActiveSupport::TestCase
  setup do
    @service = BrowserCacheService.instance
    @response = ActionDispatch::Response.new
    @request = ActionDispatch::TestRequest.create
  end

  teardown do
    Rails.cache.clear
  end

  # Singleton tests
  test 'is a singleton' do
    assert_equal @service, BrowserCacheService.instance
  end

  test 'class methods delegate to instance' do
    assert BrowserCacheService.respond_to?(:set_headers)
    assert BrowserCacheService.respond_to?(:cache_page)
    assert BrowserCacheService.respond_to?(:no_cache)
    assert BrowserCacheService.respond_to?(:set_etag)
  end

  # HTML headers tests
  test 'sets private cache headers for HTML with authenticated user' do
    @response.content_type = 'text/html'
    user = users(:one)
    
    @service.set_headers(@response, @request, user)
    
    assert_equal 'private, must-revalidate, max-age=0', @response.headers['Cache-Control']
    assert_equal 'Accept-Encoding, Cookie', @response.headers['Vary']
  end

  test 'sets public cache headers for HTML without user' do
    @response.content_type = 'text/html'
    
    @service.set_headers(@response, @request, nil)
    
    assert_equal 'public, max-age=60, must-revalidate', @response.headers['Cache-Control']
    assert_equal 'Accept-Encoding, Cookie', @response.headers['Vary']
  end

  # JSON headers tests
  test 'sets cache headers for cacheable JSON API endpoints' do
    @response.content_type = 'application/json'
    @request.path = '/api/v1/restaurants/1/menus'
    
    @service.set_headers(@response, @request, users(:one))
    
    assert_equal 'private, max-age=300, must-revalidate', @response.headers['Cache-Control']
    assert_equal 'Accept, Accept-Encoding', @response.headers['Vary']
  end

  test 'sets no-cache headers for non-cacheable JSON endpoints' do
    @response.content_type = 'application/json'
    @request.path = '/api/v1/orders'
    
    @service.set_headers(@response, @request, users(:one))
    
    assert_includes @response.headers['Cache-Control'], 'no-cache'
    assert_includes @response.headers['Cache-Control'], 'no-store'
  end

  # Static asset headers tests
  test 'sets immutable cache headers for JavaScript' do
    @response.content_type = 'application/javascript'
    
    @service.set_headers(@response, @request, nil)
    
    assert_equal 'public, max-age=31536000, immutable', @response.headers['Cache-Control']
    assert_equal 'Accept-Encoding', @response.headers['Vary']
  end

  test 'sets immutable cache headers for CSS' do
    @response.content_type = 'text/css'
    
    @service.set_headers(@response, @request, nil)
    
    assert_equal 'public, max-age=31536000, immutable', @response.headers['Cache-Control']
    assert_equal 'Accept-Encoding', @response.headers['Vary']
  end

  test 'sets cache headers for images' do
    @response.content_type = 'image/png'
    
    @service.set_headers(@response, @request, nil)
    
    assert_equal 'public, max-age=86400, immutable', @response.headers['Cache-Control']
    assert_equal 'Accept-Encoding', @response.headers['Vary']
  end

  # Security headers tests
  test 'adds security headers' do
    @response.content_type = 'text/html'
    
    @service.set_headers(@response, @request, nil)
    
    assert_equal 'nosniff', @response.headers['X-Content-Type-Options']
  end

  # cache_page tests
  test 'cache_page sets appropriate headers with defaults' do
    @service.cache_page(@response)
    
    assert_includes @response.headers['Cache-Control'], 'private'
    assert_includes @response.headers['Cache-Control'], 'max-age=300'
    assert_includes @response.headers['Cache-Control'], 'must-revalidate'
    assert_equal 'Accept-Encoding, Accept', @response.headers['Vary']
  end

  test 'cache_page respects custom max_age' do
    @service.cache_page(@response, max_age: 600)
    
    assert_includes @response.headers['Cache-Control'], 'max-age=600'
  end

  test 'cache_page sets public cache when specified' do
    @service.cache_page(@response, public: true)
    
    assert_includes @response.headers['Cache-Control'], 'public'
    assert_not_includes @response.headers['Cache-Control'], 'private'
  end

  test 'cache_page adds stale-while-revalidate when specified' do
    @service.cache_page(@response, stale_while_revalidate: 60)
    
    assert_includes @response.headers['Cache-Control'], 'stale-while-revalidate=60'
  end

  test 'cache_page without must_revalidate' do
    @service.cache_page(@response, must_revalidate: false)
    
    assert_not_includes @response.headers['Cache-Control'], 'must-revalidate'
  end

  # no_cache tests
  test 'no_cache sets all no-cache headers' do
    @service.no_cache(@response)
    
    assert_includes @response.headers['Cache-Control'], 'no-cache'
    assert_includes @response.headers['Cache-Control'], 'no-store'
    assert_includes @response.headers['Cache-Control'], 'must-revalidate'
    assert_equal 'no-cache', @response.headers['Pragma']
    assert_equal '0', @response.headers['Expires']
  end

  # set_etag tests
  test 'set_etag with string value' do
    @service.set_etag(@response, 'abc123')
    
    assert_equal '"abc123"', @response.headers['ETag']
  end

  test 'set_etag with object that has cache_key' do
    restaurant = restaurants(:one)
    @service.set_etag(@response, restaurant)
    
    # ETag should contain the cache key
    etag = @response.headers['ETag']
    assert_not_nil etag
    assert_match(/^"restaurants\/\d+/, etag)
  end

  test 'set_etag with weak ETag' do
    @service.set_etag(@response, 'abc123', weak: true)
    
    assert_equal 'W/"abc123"', @response.headers['ETag']
  end

  test 'set_etag generates MD5 hash for other objects' do
    value = { foo: 'bar' }
    @service.set_etag(@response, value)
    
    expected_hash = Digest::MD5.hexdigest(value.to_s)
    assert_equal "\"#{expected_hash}\"", @response.headers['ETag']
  end

  # cache_stats tests
  test 'cache_stats returns default stats when no data' do
    Rails.cache.delete('browser_cache:stats')
    
    stats = @service.cache_stats
    
    assert_equal 0, stats[:total_requests]
    assert_equal 0, stats[:cached_responses]
    assert_equal 0, stats[:no_cache_responses]
    assert_equal 0.0, stats[:cache_hit_rate]
  end

  test 'cache_stats calculates hit rate correctly' do
    Rails.cache.write('browser_cache:stats', {
      total_requests: 100,
      cached_responses: 85,
      no_cache_responses: 15,
      etag_responses: 50,
      by_content_type: {}
    })
    
    stats = @service.cache_stats
    
    assert_equal 100, stats[:total_requests]
    assert_equal 85, stats[:cached_responses]
    assert_equal 85.0, stats[:cache_hit_rate]
  end

  # Header skipping tests
  test 'does not override existing Cache-Control headers' do
    @response.headers['Cache-Control'] = 'custom-value'
    @response.content_type = 'text/html'
    
    @service.set_headers(@response, @request, nil)
    
    assert_equal 'custom-value', @response.headers['Cache-Control']
  end

  # Content type detection tests
  test 'handles missing content type with default headers' do
    @response.content_type = nil
    
    @service.set_headers(@response, @request, nil)
    
    assert_not_nil @response.headers['Cache-Control']
  end

  # Cacheable API endpoint detection tests
  test 'identifies cacheable API endpoints correctly' do
    cacheable_paths = [
      '/api/v1/restaurants/1/menus',
      '/api/v1/restaurants/123/menu_items',
      '/api/v1/restaurants/456'
    ]
    
    cacheable_paths.each do |path|
      response = ActionDispatch::Response.new
      response.content_type = 'application/json'
      @request.path = path
      
      @service.set_headers(response, @request, users(:one))
      
      assert_includes response.headers['Cache-Control'], 'max-age=300',
                      "Expected #{path} to be cacheable"
    end
  end

  test 'identifies non-cacheable API endpoints correctly' do
    non_cacheable_paths = [
      '/api/v1/orders',
      '/api/v1/payments',
      '/api/v1/users/current'
    ]
    
    non_cacheable_paths.each do |path|
      response = ActionDispatch::Response.new
      response.content_type = 'application/json'
      @request.path = path
      
      @service.set_headers(response, @request, users(:one))
      
      assert_includes response.headers['Cache-Control'], 'no-cache',
                      "Expected #{path} to be non-cacheable"
    end
  end

  # Class method delegation tests
  test 'class methods work correctly' do
    response = ActionDispatch::Response.new
    response.content_type = 'text/html'
    
    BrowserCacheService.set_headers(response, @request, nil)
    
    assert_not_nil response.headers['Cache-Control']
  end

  test 'cache_page class method works' do
    response = ActionDispatch::Response.new
    
    BrowserCacheService.cache_page(response, max_age: 600)
    
    assert_includes response.headers['Cache-Control'], 'max-age=600'
  end

  test 'no_cache class method works' do
    response = ActionDispatch::Response.new
    
    BrowserCacheService.no_cache(response)
    
    assert_includes response.headers['Cache-Control'], 'no-cache'
  end

  test 'set_etag class method works' do
    response = ActionDispatch::Response.new
    
    BrowserCacheService.set_etag(response, 'test123')
    
    assert_equal '"test123"', response.headers['ETag']
  end
end
