module Ordritems
  class TransitionStatus
    ALLOWED_TRANSITIONS = {
      'pending' => 'preparing',
      'preparing' => 'ready',
      'ready' => 'collected',
    }.freeze

    TIMESTAMP_COLUMN = {
      'preparing' => :preparing_at,
      'ready' => :ready_at,
      'collected' => :collected_at,
    }.freeze

    def initialize(ordritem:, to_status:, actor: nil)
      @ordritem  = ordritem
      @to_status = to_status.to_s
      @actor     = actor
    end

    def call
      return feature_disabled_result unless Flipper.enabled?(:ordritem_realtime_tracking)

      from = @ordritem.fulfillment_status.to_s

      # Idempotent — already in target state, no new event
      if from == @to_status
        return { success: true, ordritem: @ordritem, noop: true }
      end

      unless ALLOWED_TRANSITIONS[from] == @to_status
        return { success: false, error: 'Invalid transition' }
      end

      transition!
    rescue ActiveRecord::RecordInvalid => e
      { success: false, error: e.message }
    rescue StandardError => e
      Rails.logger.error("[Ordritems::TransitionStatus] #{e.class}: #{e.message}")
      { success: false, error: e.message }
    end

    private

    def transition!
      now = Time.current
      timestamp_col = TIMESTAMP_COLUMN[@to_status]
      from = @ordritem.fulfillment_status.to_s

      ActiveRecord::Base.transaction do
        @ordritem.update!(
          :fulfillment_status => @to_status,
          :fulfillment_status_changed_at => now,
          timestamp_col => now,
        )

        OrdritemEvent.create!(
          ordritem_id: @ordritem.id,
          ordr_id: @ordritem.ordr_id,
          restaurant_id: @ordritem.ordr.restaurant_id,
          event_type: 'fulfillment_status_changed',
          from_status: Ordritem.fulfillment_statuses[from],
          to_status: Ordritem.fulfillment_statuses[@to_status],
          occurred_at: now,
          actor_type: @actor.instance_of?(::NilClass) ? nil : @actor.class.name,
          actor_id: @actor.respond_to?(:id) ? @actor.id : nil,
          metadata: {
            station: @ordritem.station,
          },
        )
      end

      { success: true, ordritem: @ordritem }
    end

    def feature_disabled_result
      { success: false, error: 'Feature not enabled' }
    end
  end
end
