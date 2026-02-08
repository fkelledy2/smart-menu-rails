class OrderStateReducer
  Result = Struct.new(:state, :unsupported_events, keyword_init: true)

  def self.reduce(events)
    state = { status: nil, items: {} }
    unsupported = []

    Array(events)
      .sort_by { |e| [safe_int(e.sequence), safe_time(e.occurred_at), safe_time(e.created_at), safe_int(e.id)] }
      .each do |event|
        case event.event_type.to_s
        when 'status_changed'
          state[:status] = event.payload['to'] || event.payload[:to]
        when 'bill_requested'
          state[:status] = 'billrequested'
        when 'paid'
          state[:status] = 'paid'
        when 'closed'
          state[:status] = 'closed'
        when 'item_added'
          menuitem_id = event.payload['menuitem_id'] || event.payload[:menuitem_id]
          qty = (event.payload['qty'] || event.payload[:qty] || 1).to_i
          key = event.entity_id || "seq:#{event.sequence}"
          state[:items][key] = { menuitem_id: menuitem_id, qty: qty }
        when 'item_removed'
          id = event.payload['ordritem_id'] || event.payload[:ordritem_id] || event.entity_id
          state[:items].delete(id)
        else
          unsupported << event
        end
      end

    Result.new(state: state, unsupported_events: unsupported)
  end

  def self.safe_int(v)
    v.to_i
  rescue StandardError
    0
  end

  def self.safe_time(v)
    v.respond_to?(:to_time) ? v.to_time : Time.zone.at(0)
  rescue StandardError
    Time.zone.at(0)
  end
end
