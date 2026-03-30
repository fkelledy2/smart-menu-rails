# frozen_string_literal: true

# Nightly Sidekiq cron job that recomputes dining duration patterns for all
# active restaurants. Patterns are used by WaitTime::EstimationService to
# provide historically-informed wait time estimates.
#
# Runs at 2am UTC nightly via Sidekiq scheduler.
# Can also be triggered manually: UpdateDiningPatternsJob.perform_later
# Or for a single restaurant: UpdateDiningPatternsJob.perform_later(restaurant_id: 42)
class UpdateDiningPatternsJob < ApplicationJob
  queue_as :low_priority

  sidekiq_options retry: 2, backtrace: true

  def perform(restaurant_id: nil)
    restaurants = if restaurant_id
                    Restaurant.where(id: restaurant_id)
                  else
                    Restaurant.where(status: :active)
                  end

    restaurants.find_each do |restaurant|
      WaitTime::PatternUpdater.new(restaurant).update!
    rescue StandardError => e
      Rails.logger.error(
        "[UpdateDiningPatternsJob] failed for restaurant_id=#{restaurant.id}: #{e.class}: #{e.message}",
      )
      # Continue to next restaurant rather than aborting the whole batch.
    end

    Rails.logger.info("[UpdateDiningPatternsJob] complete — processed #{restaurants.count} restaurant(s)")
  end
end
