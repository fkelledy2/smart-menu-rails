class Payments::ReconciliationJob < ApplicationJob
  queue_as :default

  def perform(provider: nil, since: 24.hours.ago)
    Rails.logger.info(
      "[Payments::ReconciliationJob] noop v1 provider=#{provider.inspect} since=#{since}"
    )
  end
end
