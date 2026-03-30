# frozen_string_literal: true

# Computes estimated wait time (in minutes) for a given party size at a restaurant.
#
# Algorithm:
#   1. Load current table occupancy — which tables are active and how long they've been occupied.
#   2. For each occupied table that could fit the party, estimate remaining dining time
#      using historical patterns (or a default) minus elapsed time so far.
#   3. Find the minimum positive remaining time across candidate tables.
#   4. If no tables are free, return that minimum remaining time.
#   5. If a table is already free that fits the party, return 0 (immediate seating).
#
# All pattern queries hit the read replica (read_from_replica).
# Result is capped at CustomerWaitQueue::DEFAULT_WAIT_MINUTES when no data is available.
module WaitTime
  class EstimationService
    # Cached estimate is valid for this many seconds before recompute is forced.
    CACHE_TTL = 5.minutes.freeze

    # Minimum number of historical samples required to trust a pattern.
    MIN_SAMPLE_THRESHOLD = 5

    def initialize(restaurant)
      @restaurant = restaurant
    end

    # Returns a hash: { party_size => estimated_wait_minutes }
    # for each standard party size.
    def estimates_for_standard_sizes
      CustomerWaitQueue::STANDARD_PARTY_SIZES.index_with do |size|
        estimate_for_party(size)
      end
    end

    # Returns the estimated wait in minutes for a specific party size.
    # Returns 0 if a suitable table is already free.
    def estimate_for_party(party_size)
      now = Time.current

      # Tables that fit this party and are not archived
      candidate_tables = @restaurant.tablesettings
        .where(archived: false)
        .where(capacity: party_size..)

      return 0 if candidate_tables.empty?

      # Active orders on candidate tables
      excluded = [Ordr.statuses['paid'], Ordr.statuses['closed']]
      active_table_ids = Ordr
        .unscoped
        .where(restaurant_id: @restaurant.id)
        .where.not(status: excluded)
        .where(tablesetting_id: candidate_tables.pluck(:id))
        .distinct
        .pluck(:tablesetting_id)
        .to_set

      free_table_ids = candidate_tables.pluck(:id).to_set - active_table_ids
      return 0 if free_table_ids.any?

      # All candidate tables are occupied — find the one finishing soonest
      occupied_ordrs = Ordr
        .unscoped
        .where(restaurant_id: @restaurant.id)
        .where.not(status: excluded)
        .where(tablesetting_id: active_table_ids.to_a)
        .select(:id, :tablesetting_id, :created_at, :ordercapacity)

      remaining_times = occupied_ordrs.filter_map do |ordr|
        elapsed = (now - ordr.created_at) / 60.0 # in minutes
        avg = historical_avg_for(party_size: ordr.ordercapacity.positive? ? ordr.ordercapacity : party_size,
                                 time: ordr.created_at,)
        remaining = avg - elapsed
        remaining.positive? ? remaining : 1.0 # at least 1 minute (wrapping up)
      end

      return CustomerWaitQueue::DEFAULT_WAIT_MINUTES if remaining_times.empty?

      remaining_times.min.ceil
    end

    private

    # Fetches average dining duration from DiningPattern for the given party size and time.
    # Falls back to DEFAULT_WAIT_MINUTES if insufficient data.
    def historical_avg_for(party_size:, time:)
      day = time.wday
      hour = time.hour

      # Use replica for read-only analytics query
      pattern = ApplicationRecord.on_replica do
        DiningPattern
          .where(restaurant_id: @restaurant.id, party_size: party_size,
                 day_of_week: day, hour_of_day: hour,)
          .where(sample_count: MIN_SAMPLE_THRESHOLD..)
          .first
      end

      return CustomerWaitQueue::DEFAULT_WAIT_MINUTES unless pattern

      pattern.average_duration_minutes
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.warn("[WaitTime::EstimationService] replica query failed: #{e.message}")
      CustomerWaitQueue::DEFAULT_WAIT_MINUTES
    end
  end
end
