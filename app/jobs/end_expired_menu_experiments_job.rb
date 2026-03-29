# frozen_string_literal: true

# Belt-and-suspenders Sidekiq cron job that marks experiments whose ends_at has
# elapsed as `ended`. The SmartMenu serve-time logic is already safe regardless
# (it checks ends_at directly), so this is an audit trail / status hygiene step.
#
# Runs every 15 minutes via Sidekiq cron.
class EndExpiredMenuExperimentsJob < ApplicationJob
  queue_as :default

  sidekiq_options retry: 3, backtrace: true

  def perform
    now = Time.current

    # Use update_all for a single efficient batch update — avoids N+1 callbacks
    count = MenuExperiment
      .where(status: MenuExperiment.statuses[:active])
      .where(ends_at: ...now)
      .update_all(status: MenuExperiment.statuses[:ended])

    Rails.logger.info("[EndExpiredMenuExperimentsJob] ended #{count} expired experiment(s) at #{now}")
  end
end
