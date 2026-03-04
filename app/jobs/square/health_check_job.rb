# frozen_string_literal: true

module Square
  # Verifies Square connection health by calling the Locations API.
  # Marks restaurants as degraded if the API call fails, or reconnects
  # them if a previously degraded connection is healthy again.
  # Intended to run weekly via cron/scheduler.
  #
  # Usage: Square::HealthCheckJob.perform_later
  class HealthCheckJob < ApplicationJob
    queue_as :default

    def perform
      connected_accounts.find_each do |account|
        check_account(account)
      rescue StandardError => e
        Rails.logger.error(
          "[Square::HealthCheckJob] Failed health check for " \
          "provider_account_id=#{account.id} restaurant_id=#{account.restaurant_id}: " \
          "#{e.class}: #{e.message}",
        )
      end
    end

    private

    def connected_accounts
      ProviderAccount.where(provider: :square, status: :enabled)
    end

    def check_account(account)
      restaurant = account.restaurant
      client = Payments::Providers::SquareHttpClient.new(
        access_token: account.access_token,
        environment: account.environment || SquareConfig.environment,
      )

      locations = client.get('/locations')
      location_count = (locations['locations'] || []).length

      if restaurant.provider_degraded?
        restaurant.update!(payment_provider_status: :connected)
        Rails.logger.info(
          "[Square::HealthCheckJob] Restored connection for restaurant_id=#{restaurant.id} " \
          "locations=#{location_count}",
        )
      else
        Rails.logger.info(
          "[Square::HealthCheckJob] Healthy restaurant_id=#{restaurant.id} locations=#{location_count}",
        )
      end
    rescue Payments::Providers::SquareHttpClient::SquareApiError => e
      handle_degraded(account, restaurant, e)
    end

    def handle_degraded(account, restaurant, error)
      Rails.logger.warn(
        "[Square::HealthCheckJob] Degraded restaurant_id=#{restaurant.id}: " \
        "#{error.status_code} #{error.message}",
      )

      if error.status_code == 401
        # Token invalid — mark disconnected
        restaurant.update!(payment_provider_status: :disconnected)
        account.update!(status: :disabled, disconnected_at: Time.current)
      else
        # Other error — mark degraded
        restaurant.update!(payment_provider_status: :degraded) unless restaurant.provider_degraded?
      end
    end
  end
end
