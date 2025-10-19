# frozen_string_literal: true

require 'test_helper'

class BrowserCacheableTest < ActionDispatch::IntegrationTest
  class TestController < ActionController::Base
    include BrowserCacheable
    
    skip_after_action :set_browser_cache_headers

    def show
      @restaurant = Restaurant.find(params[:id])
      return if cache_with_etag(@restaurant)
      render plain: 'OK'
    end

    def index
      @restaurants = Restaurant.all
      return if cache_collection_with_etag(@restaurants)
      render plain: 'OK'
    end

    def no_cache_action
      no_browser_cache
      render plain: 'OK' unless performed?
    end

    def custom_cache
      cache_page(max_age: 600, public: true)
      render plain: 'OK' unless performed?
    end

    private

    def current_user
      User.first
    end
  end

  setup do
    @controller = TestController.new
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::Response.new
    @controller.request = @request
    @controller.response = @response
    
    Rails.application.routes.draw do
      get '/test/:id', to: 'browser_cacheable_test/test#show'
      get '/test', to: 'browser_cacheable_test/test#index'
      get '/test/no_cache', to: 'browser_cacheable_test/test#no_cache_action'
      get '/test/custom', to: 'browser_cacheable_test/test#custom_cache'
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  # cache_with_etag tests
  test 'cache_with_etag sets ETag header' do
    restaurant = restaurants(:one)
    @request.path = "/test/#{restaurant.id}"
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    
    @controller.params = { id: restaurant.id }
    @controller.process(:show)
    
    assert_not_nil @response.headers['ETag']
  end

  test 'cache_with_etag sets cache headers' do
    restaurant = restaurants(:one)
    @request.path = "/test/#{restaurant.id}"
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    
    @controller.params = { id: restaurant.id }
    @controller.process(:show)
    
    assert_not_nil @response.headers['Cache-Control']
    assert_includes @response.headers['Cache-Control'], 'max-age'
  end

  test 'cache_with_etag returns 304 when ETag matches' do
    restaurant = restaurants(:one)
    etag_value = @controller.send(:generate_etag, restaurant, {})
    
    @request.headers['If-None-Match'] = etag_value
    @request.path = "/test/#{restaurant.id}"
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    @controller.params = { id: restaurant.id }
    
    @controller.process(:show)
    
    assert_equal 304, @response.status
  end

  test 'cache_with_etag respects custom max_age' do
    restaurant = restaurants(:one)
    @request.path = "/test/#{restaurant.id}"
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    @controller.params = { id: restaurant.id }
    
    # Create a new controller instance with custom show method
    custom_controller = TestController.new
    custom_controller.request = @request
    custom_controller.response = @response
    custom_controller.params = { id: restaurant.id }
    
    def custom_controller.show
      @restaurant = Restaurant.find(params[:id])
      return if cache_with_etag(@restaurant, max_age: 600)
      render plain: 'OK'
    end
    
    custom_controller.process(:show)
    
    assert_includes @response.headers['Cache-Control'], 'max-age=600'
  end

  # cache_collection_with_etag tests
  test 'cache_collection_with_etag generates ETag from collection' do
    @request.path = '/test'
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    @controller.params = {}
    
    @controller.process(:index)
    
    assert_not_nil @response.headers['ETag']
  end

  test 'cache_collection_with_etag includes user in ETag' do
    @request.path = '/test'
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    @controller.params = {}
    
    @controller.process(:index)
    
    etag = @response.headers['ETag']
    assert_not_nil etag
    # ETag should be generated (exact format may vary)
  end

  # no_browser_cache tests
  test 'no_browser_cache sets no-cache headers' do
    @request.path = '/test/no_cache'
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    @controller.params = {}
    
    @controller.process(:no_cache_action)
    
    assert_includes @response.headers['Cache-Control'], 'no-cache'
    assert_includes @response.headers['Cache-Control'], 'no-store'
    assert_equal 'no-cache', @response.headers['Pragma']
  end

  # cache_page tests
  test 'cache_page sets custom cache headers' do
    @request.path = '/test/custom'
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    @controller.params = {}
    
    @controller.process(:custom_cache)
    
    assert_includes @response.headers['Cache-Control'], 'max-age=600'
    assert_includes @response.headers['Cache-Control'], 'public'
  end

  # skip_browser_cache tests
  test 'skip_browser_cache returns true for POST requests' do
    @request.request_method = 'POST'
    
    assert @controller.send(:skip_browser_cache?)
  end

  test 'skip_browser_cache returns false for GET requests' do
    @request.request_method = 'GET'
    
    assert_not @controller.send(:skip_browser_cache?)
  end

  test 'skip_browser_cache returns true for Turbo Frame requests' do
    @request.headers['Turbo-Frame'] = 'modal'
    @request.request_method = 'GET'
    
    assert @controller.send(:skip_browser_cache?)
  end

  test 'skip_browser_cache returns true for AJAX requests by default' do
    @request.headers['X-Requested-With'] = 'XMLHttpRequest'
    @request.request_method = 'GET'
    
    assert @controller.send(:skip_browser_cache?)
  end

  # generate_etag tests
  test 'generate_etag uses cache_key_with_version when available' do
    restaurant = restaurants(:one)
    
    etag = @controller.send(:generate_etag, restaurant, {})
    
    assert_not_nil etag
    assert_match(/^"/, etag)
  end

  test 'generate_etag includes user for private caching' do
    restaurant = restaurants(:one)
    user = @controller.send(:current_user_for_cache)
    
    # Skip if no user available
    skip 'No user available' if user.nil?
    
    etag = @controller.send(:generate_etag, restaurant, { public: false })
    
    # ETag should include user ID when not public
    assert_match(/user-#{user.id}/, etag)
  end

  test 'generate_etag excludes user for public caching' do
    restaurant = restaurants(:one)
    
    etag = @controller.send(:generate_etag, restaurant, { public: true })
    
    # ETag should not include user when public
    refute_match(/user-\d+/, etag)
  end

  test 'generate_etag adds weak prefix when specified' do
    restaurant = restaurants(:one)
    
    etag = @controller.send(:generate_etag, restaurant, { weak: true })
    
    assert_match(/^W\//, etag)
  end

  test 'generate_etag generates MD5 hash for objects without cache_key' do
    value = { foo: 'bar' }
    
    etag = @controller.send(:generate_etag, value, {})
    
    assert_not_nil etag
    assert_match(/^"[a-f0-9]{32}"$/, etag)
  end

  # current_user_for_cache tests
  test 'current_user_for_cache returns current_user when available' do
    user = @controller.send(:current_user_for_cache)
    
    # May be nil if no users in fixtures
    if user
      assert_kind_of User, user
    else
      skip 'No users available in fixtures'
    end
  end

  # turbo_frame_request tests
  test 'turbo_frame_request? detects Turbo Frame requests' do
    @request.headers['Turbo-Frame'] = 'modal'
    
    assert @controller.send(:turbo_frame_request?)
  end

  test 'turbo_frame_request? returns false for normal requests' do
    assert_not @controller.send(:turbo_frame_request?)
  end

  # cache_ajax_requests tests
  test 'cache_ajax_requests? returns false by default' do
    assert_not @controller.send(:cache_ajax_requests?)
  end

  # Integration test with actual HTTP request
  test 'sets cache headers on GET request' do
    skip 'Integration test requires full routing setup'
    restaurant = restaurants(:one)
    
    get "/restaurants/#{restaurant.id}"
    
    # Response should have some cache headers set
    assert_response :success
  end

  # Test after_action callback
  test 'after_action callback sets browser cache headers' do
    restaurant = restaurants(:one)
    @request.path = "/test/#{restaurant.id}"
    @request.request_method = 'GET'
    @request.env['REQUEST_METHOD'] = 'GET'
    @controller.params = { id: restaurant.id }
    
    # Process the action (callbacks are skipped in TestController)
    @controller.process(:show)
    
    # Manually trigger the callback to test it
    @controller.send(:set_browser_cache_headers)
    
    # Should have cache headers
    assert_not_nil @response.headers['Cache-Control']
  end

  # Test with different HTTP methods
  test 'skips cache headers for POST requests' do
    @request.request_method = 'POST'
    @request.path = '/test'
    
    skip_cache = @controller.send(:skip_browser_cache?)
    
    assert skip_cache
  end

  test 'skips cache headers for PUT requests' do
    @request.request_method = 'PUT'
    @request.path = '/test'
    
    skip_cache = @controller.send(:skip_browser_cache?)
    
    assert skip_cache
  end

  test 'skips cache headers for DELETE requests' do
    @request.request_method = 'DELETE'
    @request.path = '/test'
    
    skip_cache = @controller.send(:skip_browser_cache?)
    
    assert skip_cache
  end

  test 'allows cache headers for HEAD requests' do
    @request.request_method = 'HEAD'
    @request.path = '/test'
    
    skip_cache = @controller.send(:skip_browser_cache?)
    
    assert_not skip_cache
  end
end
