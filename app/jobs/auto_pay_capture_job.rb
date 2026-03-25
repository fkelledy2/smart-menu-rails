class AutoPayCaptureJob < ApplicationJob
  queue_as :payments

  # Prevent double-charges: only one job per ordr_id should be running at a time.
  # Sidekiq unique jobs deduplication is relied upon via the unique key below.
  sidekiq_options retry: 2, backtrace: true, unique: :until_executed, unique_args: ->(args) { [args.first] }

  def perform(ordr_id)
    ordr = Ordr.find_by(id: ordr_id)

    unless ordr
      Rails.logger.warn("[AutoPayCaptureJob] Ordr ##{ordr_id} not found — skipping")
      return
    end

    # Idempotency guard: do not re-run if already succeeded
    if ordr.auto_pay_status == 'succeeded'
      Rails.logger.info("[AutoPayCaptureJob] Ordr ##{ordr_id} already captured — skipping")
      return
    end

    # Guard: only capture orders that are in a capturable state
    unless capturable?(ordr)
      Rails.logger.info(
        "[AutoPayCaptureJob] Ordr ##{ordr_id} not capturable (status=#{ordr.status} " \
        "auto_pay_enabled=#{ordr.auto_pay_enabled} payment_on_file=#{ordr.payment_on_file}) — skipping",
      )
      return
    end

    result = AutoPay::CaptureService.new(ordr: ordr).call

    if result.failure?
      Rails.logger.warn("[AutoPayCaptureJob] Capture failed for ordr=#{ordr_id}: #{result.error}")
    else
      Rails.logger.info("[AutoPayCaptureJob] Capture succeeded for ordr=#{ordr_id}")
    end
  rescue StandardError => e
    Rails.logger.error("[AutoPayCaptureJob] Unexpected error for ordr=#{ordr_id}: #{e.class}: #{e.message}")
    raise
  end

  private

  def capturable?(ordr)
    return false unless ordr.auto_pay_enabled?
    return false unless ordr.payment_on_file?
    return false if ordr.paid? || ordr.closed?

    # Accept billrequested or any earlier state — staff can also trigger manually
    true
  end
end
