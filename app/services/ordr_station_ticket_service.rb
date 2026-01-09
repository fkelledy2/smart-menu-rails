class OrdrStationTicketService
  class << self
    def submit_unsubmitted_items!(order)
      return false if order.blank?

      # Treat items without a station ticket as unsubmitted.
      # Some client paths may already set status to 20 (ordered) before the explicit submit.
      unsubmitted = order.ordritems.includes(:menuitem).where(status: [0, 20], ordr_station_ticket_id: nil)
      return false if unsubmitted.empty?

      by_station = { kitchen: [], bar: [] }
      unsubmitted.each do |ordritem|
        station = station_for_menuitem(ordritem.menuitem)
        next unless station
        by_station[station] << ordritem
      end

      created_any = false

      ActiveRecord::Base.transaction do
        by_station.each do |station, items|
          next if items.empty?

          ticket = create_next_ticket!(order: order, station: station)
          items.each do |item|
            attrs = { ordr_station_ticket_id: ticket.id }
            attrs[:status] = 20 if item.status.to_i == 0
            item.update!(attrs)
          end

          created_any = true
        end

        if order.status == 'opened'
          order.update!(status: :ordered)
        end
      end

      created_any
    end

    def rollup_order_status_if_ready!(order)
      return if order.blank?
      return if order.status.in?(%w[delivered billrequested paid closed])

      tickets = OrdrStationTicket.where(ordr_id: order.id)
      return if tickets.empty?

      all_ready = tickets.all? { |t| t.status == 'ready' }
      return unless all_ready

      # Only advance to ready if we're still in the prep flow
      if order.status.in?(%w[opened ordered preparing])
        order.update!(status: :ready)
      end
    end

    def broadcast_ticket_event(ticket, event:, old_status: nil, new_status: nil)
      return if ticket.blank?

      payload = {
        event: event,
        ticket: ticket_payload(ticket),
        timestamp: Time.current.iso8601,
      }

      if event == 'status_change'
        payload[:old_status] = old_status
        payload[:new_status] = new_status
      end

      stream = stream_name(ticket.restaurant_id, ticket.station)
      ActionCable.server.broadcast(stream, payload)
    end

    def stream_name(restaurant_id, station)
      "#{station}_#{restaurant_id}"
    end

    private

    def stations_for_order(order)
      # Only consider items that are actually in the order workflow
      # (opened items are not yet submitted)
      return [] if order.status.in?(%w[delivered billrequested paid closed])

      items = order.ordritems.includes(:menuitem).where(status: [20, 22, 24, 25, 30, 35, 40])
      return [] if items.empty?

      stations = []
      items.each do |ordritem|
        station = station_for_menuitem(ordritem.menuitem)
        stations << station if station
      end

      stations.uniq
    end

    def station_for_menuitem(menuitem)
      return nil if menuitem.blank?

      if menuitem.itemtype == 'food'
        :kitchen
      else
        # beverage + wine
        :bar
      end
    end

    def ticket_payload(ticket)
      order = ticket.ordr
      relevant_items = ticket.ordritems.includes(:menuitem, :ordritemnotes)

      {
        id: ticket.id,
        station: ticket.station,
        status: ticket.status,
        sequence: ticket.sequence,
        order_id: order.id,
        table: order.tablesetting&.name,
        created_at: ticket.created_at,
        items: relevant_items.map do |item|
          {
            id: item.id,
            name: item.menuitem&.name,
            notes: item.ordritemnotes.map(&:note),
          }
        end,
      }
    end

    def create_next_ticket!(order:, station:)
      next_sequence = OrdrStationTicket.where(ordr_id: order.id, station: station).maximum(:sequence).to_i + 1

      OrdrStationTicket.create!(
        restaurant_id: order.restaurant_id,
        ordr_id: order.id,
        station: station,
        status: :ordered,
        sequence: next_sequence,
        submitted_at: Time.current,
      )
    end
  end
end
