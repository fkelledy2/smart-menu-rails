module Ordritems
  class TransitionGroup
    def initialize(ordr_id:, station:, from_status:, to_status:, actor: nil)
      @ordr_id     = ordr_id
      @station     = station.to_s
      @from_status = from_status.to_s
      @to_status   = to_status.to_s
      @actor       = actor
    end

    def call
      return feature_disabled_result unless Flipper.enabled?(:ordritem_realtime_tracking)

      items = Ordritem
        .where(
          ordr_id: @ordr_id,
          station: Ordritem.stations[@station],
          fulfillment_status: Ordritem.fulfillment_statuses[@from_status],
        )

      transitioned_count = 0
      skipped_count      = 0
      errors             = []

      items.find_each do |item|
        result = Ordritems::TransitionStatus.new(
          ordritem: item,
          to_status: @to_status,
          actor: @actor,
        ).call

        if result[:success]
          result[:noop] ? (skipped_count += 1) : (transitioned_count += 1)
        else
          errors << { ordritem_id: item.id, error: result[:error] }
          skipped_count += 1
        end
      end

      {
        station: @station,
        from_status: @from_status,
        to_status: @to_status,
        transitioned_count: transitioned_count,
        skipped_count: skipped_count,
        errors: errors,
      }
    end

    private

    def feature_disabled_result
      {
        station: @station,
        from_status: @from_status,
        to_status: @to_status,
        transitioned_count: 0,
        skipped_count: 0,
        errors: [{ error: 'Feature not enabled' }],
      }
    end
  end
end
