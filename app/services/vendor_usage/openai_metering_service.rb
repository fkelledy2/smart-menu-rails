# frozen_string_literal: true

module VendorUsage
  # Records OpenAI usage via internal instrumentation.
  # Called from application code after each OpenAI API call.
  # A daily rollup job aggregates these into ExternalServiceDailyUsage records.
  #
  # Usage tracking is stored in Redis counters (keyed by date + dimension)
  # and rolled up once per day by OpenaiUsageRollupJob.
  class OpenaiMeteringService
    KEY_PREFIX = 'openai_usage'
    TTL_SECONDS = 8.days.to_i

    DIMENSIONS = %w[
      dalle_images
      gpt4o_input_tokens
      gpt4o_output_tokens
      whisper_seconds
    ].freeze

    # Record a single usage event.
    # @param dimension [String] one of DIMENSIONS
    # @param units [Numeric] quantity to add
    # @param date [Date] defaults to today
    def self.record(dimension:, units:, date: Date.current)
      new.record(dimension: dimension, units: units, date: date)
    end

    # Roll up Redis counters into ExternalServiceDailyUsage for a given date.
    # Called by OpenaiUsageRollupJob.
    def self.rollup(date: Date.yesterday)
      new.rollup(date: date)
    end

    def record(dimension:, units:, date: Date.current)
      return unless DIMENSIONS.include?(dimension.to_s)

      redis_key = redis_key_for(dimension, date)
      redis.incrby(redis_key, units.to_i)
      redis.expire(redis_key, TTL_SECONDS)
    rescue StandardError => e
      # Metering should never break application flow
      Rails.logger.warn("[VendorUsage::OpenaiMeteringService] record failed: #{e.message}")
    end

    def rollup(date: Date.yesterday)
      DIMENSIONS.each do |dimension|
        redis_key = redis_key_for(dimension, date)
        raw_value = redis.get(redis_key).to_i

        next if raw_value.zero?

        ExternalServiceDailyUsage.upsert_usage(
          date: date,
          service: 'openai',
          dimension: dimension,
          units: raw_value,
          unit_type: unit_type_for(dimension),
        )
      end
    rescue StandardError => e
      Rails.logger.error("[VendorUsage::OpenaiMeteringService] rollup failed: #{e.message}")
    end

    private

    def redis_key_for(dimension, date)
      "#{KEY_PREFIX}:#{date.iso8601}:#{dimension}"
    end

    def unit_type_for(dimension)
      case dimension
      when 'dalle_images'             then 'images'
      when /tokens/                   then 'tokens'
      when 'whisper_seconds'          then 'seconds'
      else 'count'
      end
    end

    def redis
      @redis ||= Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'))
    end
  end
end
