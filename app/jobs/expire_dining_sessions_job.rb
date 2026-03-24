class ExpireDiningSessionsJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform
    expired_count = DiningSession.expired.update_all(active: false)
    Rails.logger.info("[ExpireDiningSessionsJob] Deactivated #{expired_count} expired dining sessions")
  rescue StandardError => e
    Rails.logger.error("[ExpireDiningSessionsJob] Failed: #{e.class}: #{e.message}")
    raise
  end
end
