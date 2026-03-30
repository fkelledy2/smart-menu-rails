# frozen_string_literal: true

# Computes and persists dining duration patterns from historical closed orders.
# Called nightly by UpdateDiningPatternsJob.
#
# A "dining duration" for an order is: paidAt (or updated_at for closed) - created_at.
# Orders with zero or missing duration are excluded.
# Only orders with status = closed or paid are analysed.
module WaitTime
  class PatternUpdater
    # Minimum orders needed to compute a meaningful pattern for a bucket.
    MIN_SAMPLE_SIZE = 3

    # Only consider orders from the last N days for pattern computation.
    LOOKBACK_DAYS = 90

    def initialize(restaurant)
      @restaurant = restaurant
    end

    # Compute and upsert DiningPattern records for all observed buckets.
    # Returns the count of patterns upserted.
    def update!
      cutoff = LOOKBACK_DAYS.days.ago

      # Fetch completed orders with duration data, hitting replica (fallback to primary).
      raw_orders = ApplicationRecord.on_replica do
        Ordr
          .unscoped
          .where(restaurant_id: @restaurant.id)
          .where(status: [Ordr.statuses['closed'], Ordr.statuses['paid']])
          .where(created_at: cutoff..)
          .where.not(paidAt: nil)
          .select(:id, :ordercapacity, :created_at, :paidAt)
          .to_a
      end

      return 0 if raw_orders.empty?

      # Build buckets: { [party_size, day_of_week, hour_of_day] => [durations] }
      buckets = Hash.new { |h, k| h[k] = [] }

      raw_orders.each do |ordr|
        duration_min = (ordr.paidAt - ordr.created_at) / 60.0
        next unless duration_min.positive? && duration_min < 600 # skip outliers > 10h

        party = ordr.ordercapacity.positive? ? ordr.ordercapacity : 2
        bucket_key = [party, ordr.created_at.wday, ordr.created_at.hour]
        buckets[bucket_key] << duration_min
      end

      count = 0
      now = Time.current

      buckets.each do |(party_size, day_of_week, hour_of_day), durations|
        next if durations.size < MIN_SAMPLE_SIZE

        sorted = durations.sort
        avg = durations.sum / durations.size.to_f
        median = percentile(sorted, 50)

        DiningPattern.upsert( # rubocop:disable Rails/SkipsModelValidations
          {
            restaurant_id: @restaurant.id,
            party_size: party_size,
            day_of_week: day_of_week,
            hour_of_day: hour_of_day,
            average_duration_minutes: avg.round(2),
            median_duration_minutes: median.round(2),
            min_duration_minutes: sorted.first.round(2),
            max_duration_minutes: sorted.last.round(2),
            sample_count: durations.size,
            last_calculated_at: now,
            created_at: now,
            updated_at: now,
          },
          unique_by: %i[restaurant_id party_size day_of_week hour_of_day],
          update_only: %i[
            average_duration_minutes
            median_duration_minutes
            min_duration_minutes
            max_duration_minutes
            sample_count
            last_calculated_at
          ],
        )

        count += 1
      end

      Rails.logger.info(
        "[WaitTime::PatternUpdater] restaurant_id=#{@restaurant.id} upserted #{count} patterns",
      )

      count
    end

    private

    def percentile(sorted_array, pct)
      return sorted_array.first if sorted_array.one?

      index = (pct / 100.0) * (sorted_array.length - 1)
      lower = sorted_array[index.floor]
      upper = sorted_array[index.ceil]
      lower + ((upper - lower) * (index - index.floor))
    end
  end
end
