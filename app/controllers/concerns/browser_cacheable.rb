# frozen_string_literal: true

# BrowserCacheable
#
# Controller concern that adds browser caching capabilities to controllers.
# Automatically sets appropriate cache headers and provides helper methods
# for ETag-based conditional requests.
#
# Usage:
#   class RestaurantsController < ApplicationController
#     include BrowserCacheable
#
#     def show
#       @restaurant = Restaurant.find(params[:id])
#       cache_with_etag(@restaurant)
#     end
#   end
#
module BrowserCacheable
  extend ActiveSupport::Concern

  included do
    after_action :set_browser_cache_headers, unless: :skip_browser_cache?
  end

  private

  # Set browser cache headers automatically
  def set_browser_cache_headers
    BrowserCacheService.set_headers(response, request, current_user_for_cache)
  end

  # Cache page with ETag support
  # @param resource [Object] Resource to generate ETag from
  # @param options [Hash] Additional options
  # @option options [Boolean] :public Public caching (default: false)
  # @option options [Integer] :max_age Maximum age in seconds
  # @option options [Boolean] :weak Use weak ETag (default: false)
  # @return [Boolean] True if 304 was sent, false otherwise
  def cache_with_etag(resource, options = {})
    etag_value = generate_etag(resource, options)
    
    # Check if client has current version
    if request.headers['If-None-Match'] == etag_value
      head :not_modified
      return true
    end

    # Set ETag header
    BrowserCacheService.set_etag(response, etag_value, weak: options[:weak] || false)
    
    # Set cache headers
    cache_options = {
      max_age: options[:max_age] || 300,
      public: options[:public] || false,
      must_revalidate: true
    }
    BrowserCacheService.cache_page(response, cache_options)
    
    false
  end

  # Cache collection with ETag support
  # @param collection [ActiveRecord::Relation] Collection to cache
  # @param options [Hash] Additional options
  # @return [Boolean] True if 304 was sent, false otherwise
  def cache_collection_with_etag(collection, options = {})
    # Generate ETag from collection's maximum updated_at and count
    etag_components = [
      collection.maximum(:updated_at)&.to_i || 0,
      collection.count,
      current_user_for_cache&.id
    ]
    
    cache_with_etag(etag_components.join('-'), options)
  end

  # Disable browser caching for this action
  def no_browser_cache
    BrowserCacheService.no_cache(response)
  end

  # Cache page with custom options
  # @param options [Hash] Caching options
  def cache_page(options = {})
    BrowserCacheService.cache_page(response, options)
  end

  # Check if browser cache should be skipped
  # @return [Boolean]
  def skip_browser_cache?
    # Skip for Turbo Frame requests
    return true if turbo_frame_request?
    
    # Skip for AJAX requests (unless explicitly enabled)
    return true if request.xhr? && !cache_ajax_requests?
    
    # Skip for POST/PUT/PATCH/DELETE
    return true unless request.get? || request.head?
    
    false
  end

  # Get current user for cache key generation
  # @return [User, nil]
  def current_user_for_cache
    respond_to?(:current_user) ? current_user : nil
  end

  # Generate ETag value from resource
  # @param resource [Object] Resource to generate ETag from
  # @param options [Hash] Options
  # @return [String] ETag value
  def generate_etag(resource, options = {})
    etag_value = if resource.respond_to?(:cache_key_with_version)
                   resource.cache_key_with_version
                 elsif resource.respond_to?(:cache_key)
                   resource.cache_key
                 elsif resource.respond_to?(:updated_at)
                   "#{resource.class.name}-#{resource.id}-#{resource.updated_at.to_i}"
                 else
                   Digest::MD5.hexdigest(resource.to_s)
                 end

    # Include user in ETag for private caching
    if current_user_for_cache && !options[:public]
      etag_value = "#{etag_value}-user-#{current_user_for_cache.id}"
    end

    # Add weak prefix if needed
    prefix = options[:weak] ? 'W/' : ''
    "#{prefix}\"#{etag_value}\""
  end

  # Check if this is a Turbo Frame request
  # @return [Boolean]
  def turbo_frame_request?
    request.headers['Turbo-Frame'].present?
  end

  # Check if AJAX requests should be cached
  # @return [Boolean]
  def cache_ajax_requests?
    false
  end
end
