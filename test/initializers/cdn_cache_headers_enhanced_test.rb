# frozen_string_literal: true

require 'test_helper'

class CdnCacheHeadersEnhancedTest < ActiveSupport::TestCase
  test 'cache_control_for includes stale-while-revalidate' do
    result = CdnCacheControl.cache_control_for('image/jpeg')
    
    assert_match /stale-while-revalidate=/, result
  end

  test 'cache_control_for with custom stale-while-revalidate' do
    result = CdnCacheControl.cache_control_for('image/jpeg', stale_while_revalidate: 3600)
    
    assert_match /stale-while-revalidate=3600/, result
  end

  test 'cache_control_for includes immutable for assets' do
    result = CdnCacheControl.cache_control_for('application/javascript')
    
    assert_match /immutable/, result
  end

  test 'cache_control_for does not include immutable for JSON' do
    result = CdnCacheControl.cache_control_for('application/json')
    
    refute_match /immutable/, result
  end

  test 'default_swr_duration returns correct duration for images' do
    duration = CdnCacheControl.default_swr_duration('image/jpeg')
    
    assert_equal 1.day.to_i, duration
  end

  test 'default_swr_duration returns correct duration for JavaScript' do
    duration = CdnCacheControl.default_swr_duration('application/javascript')
    
    assert_equal 1.week.to_i, duration
  end

  test 'default_swr_duration returns correct duration for JSON' do
    duration = CdnCacheControl.default_swr_duration('application/json')
    
    assert_equal 5.minutes.to_i, duration
  end

  test 'default_swr_duration returns default for unknown type' do
    duration = CdnCacheControl.default_swr_duration('application/unknown')
    
    assert_equal 1.hour.to_i, duration
  end

  test 'immutable_content? returns true for JavaScript' do
    assert CdnCacheControl.immutable_content?('application/javascript')
    assert CdnCacheControl.immutable_content?('text/javascript')
  end

  test 'immutable_content? returns true for CSS' do
    assert CdnCacheControl.immutable_content?('text/css')
  end

  test 'immutable_content? returns true for images' do
    assert CdnCacheControl.immutable_content?('image/png')
    assert CdnCacheControl.immutable_content?('image/jpeg')
    assert CdnCacheControl.immutable_content?('image/webp')
  end

  test 'immutable_content? returns true for fonts' do
    assert CdnCacheControl.immutable_content?('font/woff')
    assert CdnCacheControl.immutable_content?('font/woff2')
  end

  test 'immutable_content? returns false for JSON' do
    refute CdnCacheControl.immutable_content?('application/json')
  end

  test 'immutable_content? returns false for HTML' do
    refute CdnCacheControl.immutable_content?('text/html')
  end

  test 'cache_control_for returns no-cache for HTML' do
    result = CdnCacheControl.cache_control_for('text/html')
    
    assert_match /no-cache/, result
    refute_match /max-age/, result
  end

  test 'cache_control_for returns proper format for CSS' do
    result = CdnCacheControl.cache_control_for('text/css')
    
    assert_match /public/, result
    assert_match /max-age=/, result
    assert_match /stale-while-revalidate=/, result
    assert_match /immutable/, result
  end

  test 'cache_control_for handles unknown content type' do
    result = CdnCacheControl.cache_control_for('application/unknown')
    
    assert_match /public/, result
    assert_match /max-age=3600/, result # 1 hour default
  end
end
