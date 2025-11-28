# frozen_string_literal: true

# Service for generating optimized cache keys and managing cache operations
class CacheKeyService
  # Maximum Redis key length to avoid issues
  MAX_KEY_LENGTH = 250

  class << self
    # Best-effort current assets digest for cache-keying HTML with JS
    def assets_digest
      if Rails.application.config.respond_to?(:assets) && Rails.application.config.assets.respond_to?(:version)
        ver = Rails.application.config.assets.version
        return ver.to_s if ver.present?
      end

      if defined?(Rails.application.assets_manifest) && Rails.application.assets_manifest.respond_to?(:digest)
        dig = Rails.application.assets_manifest.digest
        return dig.to_s if dig.present?
      end

      return ENV['ASSETS_DIGEST'] if ENV['ASSETS_DIGEST'].present?
      return (Rails.respond_to?(:revision) ? Rails.revision : nil).to_s
    rescue StandardError
      nil
    end
    # Generate optimized cache key for menu content
    def menu_content_key(ordr:, menu:, participant: nil, **options)
      base_key = "menu_content:#{menu.id}:#{menu.updated_at.to_i}"

      # Add participant context if present
      if participant
        base_key += ":participant:#{participant.id}"
      end

      # Add order context
      base_key += ":ordr:#{ordr.id}:#{ordr.updated_at.to_i}"

      # Add optional context
      if options[:currency]
        base_key += ":currency:#{options[:currency].code}"
      end

      if options[:allergyns_updated_at]
        base_key += ":allergyns:#{options[:allergyns_updated_at].to_i}"
      end
      if options[:locale]
        base_key += ":locale:#{options[:locale]}"
      end
      digest = options[:assets_digest] || assets_digest
      if digest.present?
        base_key += ":assets:#{digest}"
      end

      # Use MD5 hash for very long keys to prevent Redis key length issues
      optimize_key_length(base_key)
    end

    # Generate cache key for modal content
    def modal_content_key(ordr:, menu:, tablesetting: nil, participant: nil, **options)
      base_key = "modals:#{menu.id}:#{menu.updated_at.to_i}"

      if ordr
        base_key += ":ordr:#{ordr.id}:#{ordr.updated_at.to_i}"
      end

      if tablesetting
        base_key += ":table:#{tablesetting.id}"
      end

      if participant
        base_key += ":participant:#{participant.id}"
      end

      if options[:currency]
        base_key += ":currency:#{options[:currency].code}"
      end

      optimize_key_length(base_key)
    end

    # Generate cache key for restaurant data
    def restaurant_cache_key(restaurant:, **options)
      base_key = "restaurant:#{restaurant.id}:#{restaurant.updated_at.to_i}"

      if options[:include_menus]
        # Include menu timestamps for invalidation
        menu_timestamps = restaurant.menus.maximum(:updated_at)
        base_key += ":menus:#{menu_timestamps.to_i}"
      end

      if options[:include_employees]
        employee_timestamps = restaurant.employees.maximum(:updated_at)
        base_key += ":employees:#{employee_timestamps.to_i}"
      end

      optimize_key_length(base_key)
    end

    # Hierarchical cache invalidation for menus
    def invalidate_menu_cache(menu_id)
      pattern = "menu_content:#{menu_id}:*"
      Rails.cache.delete_matched(pattern)
      Rails.logger.info("[CacheKeyService] Invalidated cache pattern: #{pattern}")
    end

    # Invalidate all cache for a restaurant
    def invalidate_restaurant_cache(restaurant_id)
      patterns = [
        "restaurant:#{restaurant_id}:*",
        "menu_content:*:*:*:*:restaurant:#{restaurant_id}:*",
        "modals:*:*:*:restaurant:#{restaurant_id}:*",
      ]

      patterns.each do |pattern|
        Rails.cache.delete_matched(pattern)
        Rails.logger.info("[CacheKeyService] Invalidated cache pattern: #{pattern}")
      end
    end

    # Batch cache operations for better performance
    def fetch_multiple(keys_and_options = {}, &)
      if keys_and_options.empty?
        return {}
      end

      # Use Rails cache fetch_multi for efficient batch operations
      Rails.cache.fetch_multi(*keys_and_options.keys, &)
    end

    # Batch write operations
    def write_multiple(data_hash, expires_in: 6.hours)
      return if data_hash.empty?

      # Use write_multi if available, otherwise fall back to individual writes
      if Rails.cache.respond_to?(:write_multi)
        Rails.cache.write_multi(data_hash, expires_in: expires_in)
      else
        data_hash.each do |key, value|
          Rails.cache.write(key, value, expires_in: expires_in)
        end
      end

      Rails.logger.debug { "[CacheKeyService] Batch wrote #{data_hash.size} cache entries" }
    end

    # Generate cache key for API responses
    def api_response_key(controller:, action:, params: {}, version: 'v1')
      # Create deterministic key from controller, action, and sorted params
      param_string = params.sort.to_h.to_query
      base_key = "api:#{version}:#{controller}:#{action}"

      unless param_string.empty?
        base_key += ":#{Digest::MD5.hexdigest(param_string)}"
      end

      optimize_key_length(base_key)
    end

    # Cache warming for frequently accessed data
    def warm_menu_cache(menu)
      Rails.logger.info("[CacheKeyService] Warming cache for menu #{menu.id}")

      # Pre-load menu sections and items
      menu.menusections.includes(:menuitems).find_each do |section|
        section.menuitems.each(&:touch) # Ensure cache keys are fresh
      end

      # Pre-generate common cache keys
      restaurant = menu.restaurant
      currency = Money::Currency.new(restaurant.currency || 'USD')

      base_options = {
        currency: currency,
        allergyns_updated_at: restaurant.allergyns.maximum(:updated_at),
      }

      # Generate cache keys for common scenarios (no specific order)
      require 'ostruct' unless defined?(OpenStruct)
      cache_key = menu_content_key(
        ordr: OpenStruct.new(id: 0, updated_at: Time.current),
        menu: menu,
        **base_options,
      )

      Rails.logger.debug { "[CacheKeyService] Generated warm cache key: #{cache_key}" }
    end

    private

    # Optimize key length to prevent Redis issues
    def optimize_key_length(key)
      if key.length > MAX_KEY_LENGTH
        # Keep first part readable, hash the rest
        prefix = key[0..50]
        suffix_hash = Digest::MD5.hexdigest(key)
        "#{prefix}:hash:#{suffix_hash}"
      else
        key
      end
    end
  end
end
