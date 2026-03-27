# frozen_string_literal: true

# Scheduled job: runs once per day via Sidekiq-Cron.
# Notifies the issuing admin 7 days before each active token expires.
# Also purges usage log records older than 90 days.
class JwtTokenExpiryNotificationJob
  include Sidekiq::Job

  sidekiq_options retry: 3, queue: :default

  NOTIFY_DAYS_BEFORE = 7
  LOG_RETENTION_DAYS = 90

  def perform
    notify_expiring_tokens
    purge_old_usage_logs
  end

  private

  def notify_expiring_tokens
    AdminJwtToken.expiring_soon(NOTIFY_DAYS_BEFORE).each do |token|
      next if token.admin_user&.email.blank?

      Rails.logger.info "[JwtTokenExpiryNotification] Token #{token.id} expiring #{token.expires_at.to_date}"
      AdminMailer.jwt_token_expiry_warning(token).deliver_later
    rescue StandardError => e
      Rails.logger.error "[JwtTokenExpiryNotification] Failed for token #{token.id}: #{e.message}"
    end
  end

  def purge_old_usage_logs
    count = JwtTokenUsageLog.purgeable.delete_all
    Rails.logger.info "[JwtTokenExpiryNotification] Purged #{count} usage log records older than #{LOG_RETENTION_DAYS} days"
  end
end
