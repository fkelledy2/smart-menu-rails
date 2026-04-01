module Ordritems
  class BroadcastStatusChangeJob < ApplicationJob
    queue_as :default

    def perform(ordritem_event_id)
      event = OrdritemEvent.find_by(id: ordritem_event_id)
      return unless event

      ordritem = Ordritem.find_by(id: event.ordritem_id)
      return unless ordritem

      ordr = Ordr.includes(:restaurant).find_by(id: event.ordr_id)
      return unless ordr

      menuitem = Menuitem.find_by(id: ordritem.menuitem_id)

      from_key   = Ordritem.fulfillment_statuses.key(event.from_status)
      to_key     = Ordritem.fulfillment_statuses.key(event.to_status)
      station    = ordritem.station

      order_summary = compute_order_summary(ordr)
      customer_label = order_summary[:label]

      payload = {
        type: 'order_item_status_changed',
        ordr_id: ordr.id.to_s,
        ordritem_id: ordritem.id.to_s,
        item_name: menuitem&.name.to_s,
        quantity: ordritem.quantity,
        station: station,
        from_status: from_key,
        to_status: to_key,
        customer_status_label: customer_label,
        occurred_at: event.occurred_at.utc.iso8601,
        order_summary: order_summary,
      }

      ActionCable.server.broadcast("ordr_#{ordr.id}_channel", payload)
    end

    private

    def compute_order_summary(ordr)
      statuses = Ordritem
        .where(ordr_id: ordr.id)
        .pluck(:fulfillment_status)
        .map { |s| Ordritem.fulfillment_statuses.key(s) }

      label = derive_label(statuses)
      { status: label.downcase.tr(' ', '_'), label: label }
    end

    def derive_label(statuses)
      return 'Received' if statuses.empty?
      return 'Complete' if statuses.all?('collected')
      return 'Ready'    if statuses.all?('ready')

      if statuses.any?('preparing')
        return 'Preparing'
      end

      # Mixed ready and non-collected
      if statuses.any?('ready') && statuses.any? { |s| s != 'collected' }
        return 'Partially Ready'
      end

      'Received'
    end
  end
end
