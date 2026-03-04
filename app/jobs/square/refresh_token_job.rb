# frozen_string_literal: true

module Square
  # Refreshes Square OAuth tokens that are expiring within 7 days.
  # Intended to run daily via cron/scheduler.
  #
  # Usage: Square::RefreshTokenJob.perform_later
  class RefreshTokenJob < ApplicationJob
    queue_as :default

    def perform
      expiring_accounts.find_each do |account|
        refresh_account(account)
      rescue StandardError => e
        Rails.logger.error(
          "[Square::RefreshTokenJob] Failed to refresh token for " \
          "provider_account_id=#{account.id} restaurant_id=#{account.restaurant_id}: " \
          "#{e.class}: #{e.message}",
        )
      end
    end

    private

    def expiring_accounts
      ProviderAccount.where(
        provider: :square,
        status: :enabled,
      ).where('token_expires_at IS NOT NULL AND token_expires_at < ?', 7.days.from_now)
    end

    def refresh_account(account)
      restaurant = account.restaurant
      connect = Payments::Providers::SquareConnect.new(restaurant: restaurant)
      connect.refresh_token!(provider_account: account)

      Rails.logger.info(
        "[Square::RefreshTokenJob] Refreshed token for " \
        "provider_account_id=#{account.id} restaurant_id=#{restaurant.id} " \
        "new_expires_at=#{account.reload.token_expires_at}",
      )
    end
  end
end
