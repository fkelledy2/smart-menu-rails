class OrderEventProjector
  def self.project!(ordr_id)
    ordr = Ordr.find_by(id: ordr_id)
    return unless ordr

    ordr.with_lock do
      cursor = ordr.last_projected_order_event_sequence.to_i
      events = OrderEvent.where(ordr_id: ordr.id)
        .where('sequence > ?', cursor)
        .order(:sequence)

      return if events.empty?

      events.each do |evt|
        apply_event!(ordr, evt)
        cursor = evt.sequence.to_i
      end

      if ordr.last_projected_order_event_sequence.to_i != cursor
        ordr.update_column(:last_projected_order_event_sequence, cursor)
      end
    end
  end

  def self.apply_event!(ordr, event)
    case event.event_type.to_s
    when 'status_changed'
      to = event.payload['to'] || event.payload[:to]
      return if to.blank?
      apply_status_change!(ordr, to.to_s)

    when 'bill_requested'
      return if ordr.status.to_s == 'billrequested'
      apply_status_change!(ordr, 'billrequested')

    when 'paid'
      return if ordr.status.to_s == 'paid'
      apply_status_change!(ordr, 'paid')

    when 'closed'
      return if ordr.status.to_s == 'closed'
      apply_status_change!(ordr, 'closed')

    when 'item_removed'
      line_key = event.payload['line_key'] || event.payload[:line_key]
      if line_key.present?
        Ordritem.where(ordr_id: ordr.id, line_key: line_key.to_s)
          .update_all(status: Ordritem.statuses['removed'], ordritemprice: 0.0)
        return
      end

      ordritem_id = event.payload['ordritem_id'] || event.payload[:ordritem_id] || event.entity_id
      return if ordritem_id.blank?
      Ordritem.where(ordr_id: ordr.id, id: ordritem_id)
        .update_all(status: Ordritem.statuses['removed'], ordritemprice: 0.0)

    when 'item_added'
      line_key = event.payload['line_key'] || event.payload[:line_key]
      menuitem_id = event.payload['menuitem_id'] || event.payload[:menuitem_id]
      price = event.payload['ordritemprice'] || event.payload[:ordritemprice]
      return if line_key.blank? || menuitem_id.blank?

      existing = Ordritem.find_by(ordr_id: ordr.id, line_key: line_key.to_s)
      return if existing

      ordritemprice = begin
        price.present? ? price.to_f : Menuitem.find_by(id: menuitem_id)&.price.to_f
      rescue StandardError
        0.0
      end

      Ordritem.create!(
        ordr: ordr,
        menuitem_id: menuitem_id,
        ordritemprice: ordritemprice || 0.0,
        status: :opened,
        line_key: line_key.to_s,
      )

    else
      # Unknown events are ignored for projection in v1.
      return
    end
  end

  def self.apply_status_change!(ordr, to_key)
    return if ordr.status.to_s == to_key.to_s

    to_value = Ordr.statuses[to_key.to_s]
    return if to_value.nil?

    updates = { status: to_value }
    now = Time.current
    case to_key.to_s
    when 'opened', 'ordered'
      updates[:orderedAt] = now if ordr.orderedAt.blank?
    when 'billrequested'
      updates[:billRequestedAt] = now if ordr.billRequestedAt.blank?
    when 'paid'
      updates[:paidAt] = now if ordr.paidAt.blank?
    end

    ordr.update_columns(updates)

    # Keep child ordritems in sync with parent status.
    removed_value = Ordritem.statuses['removed']
    Ordritem.where(ordr_id: ordr.id)
      .where.not(status: [to_value, removed_value])
      .update_all(status: to_value)

    # Mirror Ordr#clear_station_tickets_if_terminal without invoking callbacks.
    if %w[delivered billrequested paid closed].include?(to_key.to_s)
      Ordritem.where(ordr_id: ordr.id).where.not(ordr_station_ticket_id: nil).update_all(ordr_station_ticket_id: nil)
      ordr.ordr_station_tickets.delete_all
    end
  end

  private_class_method :apply_event!
  private_class_method :apply_status_change!
end
