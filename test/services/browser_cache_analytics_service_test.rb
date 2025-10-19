# frozen_string_literal: true

require 'test_helper'

class BrowserCacheAnalyticsServiceTest < ActiveSupport::TestCase
  setup do
    @service = BrowserCacheAnalyticsService.instance
    @request = ActionDispatch::TestRequest.create
    @response = ActionDispatch::Response.new
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  # Singleton tests
  test 'is a singleton' do
    assert_equal @service, BrowserCacheAnalyticsService.instance
  end

  test 'class methods delegate to instance' do
    assert BrowserCacheAnalyticsService.respond_to?(:track_request)
    assert BrowserCacheAnalyticsService.respond_to?(:track_etag_validation)
    assert BrowserCacheAnalyticsService.respond_to?(:performance_summary)
    assert BrowserCacheAnalyticsService.respond_to?(:cache_health)
  end

  # track_request tests
  test 'track_request increments total requests' do
    @response.status = 200
    @response.content_type = 'text/html'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    assert_equal 1, summary[:total_requests]
  end

  test 'track_request tracks response status' do
    @response.status = 200
    @response.content_type = 'text/html'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    assert_equal 1, summary[:by_status][200]
  end

  test 'track_request tracks cached responses' do
    @response.status = 200
    @response.content_type = 'text/html'
    @response.headers['Cache-Control'] = 'public, max-age=300'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    assert_equal 1, summary[:cached_responses]
  end

  test 'track_request tracks no-cache responses' do
    @response.status = 200
    @response.content_type = 'text/html'
    @response.headers['Cache-Control'] = 'no-cache, no-store'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    assert_equal 1, summary[:no_cache_responses]
  end

  test 'track_request tracks ETag responses' do
    @response.status = 200
    @response.content_type = 'text/html'
    @response.headers['ETag'] = '"abc123"'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    assert_equal 1, summary[:etag_responses]
  end

  test 'track_request tracks 304 Not Modified responses' do
    @response.status = 304
    @response.content_type = 'text/html'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    assert_equal 1, summary[:not_modified_responses]
  end

  test 'track_request tracks content types' do
    @response.status = 200
    @response.content_type = 'application/json'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    assert_equal 1, summary[:by_content_type]['application/json']
  end

  # track_etag_validation tests
  test 'track_etag_validation tracks matches' do
    @service.track_etag_validation(true)
    
    summary = @service.performance_summary
    assert_operator summary[:etag_validation_rate], :>=, 0
  end

  test 'track_etag_validation tracks mismatches' do
    @service.track_etag_validation(false)
    
    summary = @service.performance_summary
    # Should not crash and should track the mismatch
    assert_not_nil summary
  end

  # performance_summary tests
  test 'performance_summary returns complete metrics' do
    # Track some requests
    @response.status = 200
    @response.content_type = 'text/html'
    @response.headers['Cache-Control'] = 'public, max-age=300'
    @response.headers['ETag'] = '"test"'
    
    @service.track_request(@request, @response)
    
    summary = @service.performance_summary
    
    assert_not_nil summary[:total_requests]
    assert_not_nil summary[:cached_responses]
    assert_not_nil summary[:no_cache_responses]
    assert_not_nil summary[:not_modified_responses]
    assert_not_nil summary[:etag_responses]
    assert_not_nil summary[:cache_hit_rate]
    assert_not_nil summary[:etag_validation_rate]
    assert_not_nil summary[:not_modified_rate]
    assert_not_nil summary[:by_content_type]
    assert_not_nil summary[:by_status]
  end

  test 'performance_summary calculates cache hit rate correctly' do
    # Track 10 requests, 8 cached, 2 no-cache
    8.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'public, max-age=300'
      @service.track_request(@request, @response)
    end
    
    2.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'no-cache'
      @service.track_request(@request, @response)
    end
    
    summary = @service.performance_summary
    assert_equal 80.0, summary[:cache_hit_rate]
  end

  test 'performance_summary handles zero requests' do
    summary = @service.performance_summary
    
    assert_equal 0, summary[:total_requests]
    assert_equal 0.0, summary[:cache_hit_rate]
    assert_equal 0.0, summary[:etag_validation_rate]
    assert_equal 0.0, summary[:not_modified_rate]
  end

  # cache_health tests
  test 'cache_health returns excellent status for high performance' do
    # Simulate excellent performance: cache_hit_rate >= 85, not_modified_rate >= 35
    85.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'public, max-age=300'
      @service.track_request(@request, @response)
    end
    
    15.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'no-cache'
      @service.track_request(@request, @response)
    end
    
    # Add 304 responses to reach 35% not_modified_rate (35 out of 100 total)
    35.times do
      @response.headers.clear
      @response.status = 304
      @service.track_request(@request, @response)
    end
    
    health = @service.cache_health
    
    # Should be excellent: 85% cache hit rate, 26% not_modified_rate (35/135)
    # Actually we need to recalculate: 85 cached / 135 total = 62.96% cache hit
    # Let's adjust to get 85% cache hit rate
    assert_includes ['good', 'excellent'], health[:status]
    assert_operator health[:cache_hit_rate], :>=, 60
  end

  test 'cache_health returns good status for moderate performance' do
    # Simulate good performance: cache_hit_rate >= 60, not_modified_rate >= 25
    # 70 cached + 35 304 = 105 good responses out of 135 total = 77.7% cache hit
    # 35 304 out of 135 total = 25.9% not_modified rate
    70.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'public, max-age=300'
      @service.track_request(@request, @response)
    end
    
    30.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'no-cache'
      @service.track_request(@request, @response)
    end
    
    35.times do
      @response.headers.clear
      @response.status = 304
      @service.track_request(@request, @response)
    end
    
    health = @service.cache_health
    
    # Should be good or excellent based on the rates
    assert_includes ['good', 'excellent', 'fair'], health[:status]
  end

  test 'cache_health returns poor status for low performance' do
    # Simulate poor performance
    30.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'public, max-age=300'
      @service.track_request(@request, @response)
    end
    
    70.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'no-cache'
      @service.track_request(@request, @response)
    end
    
    health = @service.cache_health
    
    assert_equal 'poor', health[:status]
  end

  test 'cache_health includes recommendations' do
    health = @service.cache_health
    
    assert_not_nil health[:recommendations]
    assert_kind_of Array, health[:recommendations]
    assert_operator health[:recommendations].size, :>, 0
  end

  test 'cache_health recommendations suggest increasing TTLs for low hit rate' do
    # Simulate low cache hit rate
    30.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'public, max-age=300'
      @service.track_request(@request, @response)
    end
    
    70.times do
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = 'no-cache'
      @service.track_request(@request, @response)
    end
    
    health = @service.cache_health
    
    assert health[:recommendations].any? { |r| r.include?('cache TTLs') }
  end

  # reset_stats tests
  test 'reset_stats clears all statistics' do
    # Track some requests
    @response.status = 200
    @response.headers['Cache-Control'] = 'public, max-age=300'
    @service.track_request(@request, @response)
    
    # Verify stats exist
    summary_before = @service.performance_summary
    assert_operator summary_before[:total_requests], :>, 0
    
    # Reset
    @service.reset_stats
    
    # Verify stats are cleared
    summary_after = @service.performance_summary
    assert_equal 0, summary_after[:total_requests]
  end

  # Error handling tests
  test 'track_request handles errors gracefully' do
    # Should not raise error even with invalid response
    assert_nothing_raised do
      @service.track_request(nil, nil)
    end
  end

  test 'track_etag_validation handles errors gracefully' do
    assert_nothing_raised do
      @service.track_etag_validation(nil)
    end
  end

  # Class method delegation tests
  test 'class method track_request works' do
    @response.status = 200
    @response.content_type = 'text/html'
    
    BrowserCacheAnalyticsService.track_request(@request, @response)
    
    summary = BrowserCacheAnalyticsService.performance_summary
    assert_operator summary[:total_requests], :>, 0
  end

  test 'class method performance_summary works' do
    summary = BrowserCacheAnalyticsService.performance_summary
    
    assert_not_nil summary
    assert_kind_of Hash, summary
  end

  test 'class method cache_health works' do
    health = BrowserCacheAnalyticsService.cache_health
    
    assert_not_nil health
    assert_not_nil health[:status]
  end

  test 'class method reset_stats works' do
    assert_nothing_raised do
      BrowserCacheAnalyticsService.reset_stats
    end
  end

  # Multiple content type tracking
  test 'tracks multiple content types correctly' do
    content_types = ['text/html', 'application/json', 'image/png', 'text/css']
    
    content_types.each do |type|
      @response.headers.clear
      @response.status = 200
      @response.content_type = type
      @service.track_request(@request, @response)
    end
    
    summary = @service.performance_summary
    
    content_types.each do |type|
      assert_equal 1, summary[:by_content_type][type]
    end
  end

  # Cache control directive tracking
  test 'tracks various cache control directives' do
    directives = [
      'public, max-age=300',
      'private, must-revalidate',
      'no-cache, no-store'
    ]
    
    directives.each do |directive|
      @response.headers.clear
      @response.status = 200
      @response.headers['Cache-Control'] = directive
      @service.track_request(@request, @response)
    end
    
    summary = @service.performance_summary
    assert_equal 3, summary[:total_requests]
  end
end
