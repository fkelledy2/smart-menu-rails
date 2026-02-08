class RestaurantInsightsService
  def initialize(restaurant:, params: {})
    @restaurant = restaurant
    @params = params || {}
  end

  def top_performers
    cache_fetch('top_performers') do
      range = compute_range
      orders = filtered_orders(range)
      total_orders = orders.distinct.count(:id)

      rows = Ordritem
        .joins(:ordr)
        .joins(:menuitem)
        .where(ordrs: { id: orders.select(:id) })
        .where.not(ordritems: { status: Ordritem.statuses[:removed] })
        .where(menuitems: { status: Menuitem.statuses[:active], hidden: [false, nil] })
        .group('ordritems.menuitem_id', 'menuitems.name')
        .select(
          'ordritems.menuitem_id AS menuitem_id',
          'menuitems.name AS menuitem_name',
          'COUNT(DISTINCT ordritems.ordr_id) AS orders_with_item_count',
          'COUNT(*) AS quantity_sold',
        )
        .order(Arel.sql('orders_with_item_count DESC, quantity_sold DESC, ordritems.menuitem_id ASC'))

      rows.map do |r|
        orders_with_item_count = r.orders_with_item_count.to_i
        {
          menuitem_id: r.menuitem_id,
          menuitem_name: r.menuitem_name,
          orders_with_item_count: orders_with_item_count,
          quantity_sold: r.quantity_sold.to_i,
          share_of_orders: total_orders.positive? ? (orders_with_item_count.to_f / total_orders) : 0.0,
        }
      end
    end
  end

  def slow_movers
    cache_fetch('slow_movers') do
      range = compute_range
      orders = filtered_orders(range)
      total_orders = orders.distinct.count(:id)

      rows = Ordritem
        .joins(:ordr)
        .joins(:menuitem)
        .where(ordrs: { id: orders.select(:id) })
        .where.not(ordritems: { status: Ordritem.statuses[:removed] })
        .where(menuitems: { status: Menuitem.statuses[:active], hidden: [false, nil] })
        .group('ordritems.menuitem_id', 'menuitems.name')
        .select(
          'ordritems.menuitem_id AS menuitem_id',
          'menuitems.name AS menuitem_name',
          'COUNT(DISTINCT ordritems.ordr_id) AS orders_with_item_count',
          'COUNT(*) AS quantity_sold',
        )
        .order(Arel.sql('orders_with_item_count ASC, quantity_sold ASC, ordritems.menuitem_id ASC'))

      rows.map do |r|
        orders_with_item_count = r.orders_with_item_count.to_i
        {
          menuitem_id: r.menuitem_id,
          menuitem_name: r.menuitem_name,
          orders_with_item_count: orders_with_item_count,
          quantity_sold: r.quantity_sold.to_i,
          share_of_orders: total_orders.positive? ? (orders_with_item_count.to_f / total_orders) : 0.0,
        }
      end
    end
  end

  def prep_time_bottlenecks
    cache_fetch('prep_time_bottlenecks') do
      range = compute_range
      orders = filtered_orders(range)

      rows = Ordritem
        .joins(:ordr)
        .joins(:menuitem)
        .joins('INNER JOIN ordr_station_tickets ost ON ost.id = ordritems.ordr_station_ticket_id')
        .where(ordrs: { id: orders.select(:id) })
        .where(menuitems: { status: Menuitem.statuses[:active], hidden: [false, nil] })
        .where.not(ost: { submitted_at: nil })
        .where(ost: { status: [OrdrStationTicket.statuses[:ready], OrdrStationTicket.statuses[:collected]] })
        .group('ordritems.menuitem_id', 'menuitems.name')
        .select(
          'ordritems.menuitem_id AS menuitem_id',
          'menuitems.name AS menuitem_name',
          'COUNT(*) AS sample_size',
          'PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (ost.updated_at - COALESCE(ost.submitted_at, ordrs."orderedAt", ordrs.created_at)))) AS median_time_to_ready_seconds',
        )
        .order(Arel.sql('median_time_to_ready_seconds DESC NULLS LAST'))

      restaurant_median = restaurant_level_median_seconds(orders)

      rows.map do |r|
        median_seconds = r.median_time_to_ready_seconds.to_f
        sample_size = r.sample_size.to_i
        is_outlier = sample_size >= 10 && restaurant_median.to_f.positive? && median_seconds >= (restaurant_median.to_f * 1.5) && median_seconds >= 180

        {
          menuitem_id: r.menuitem_id,
          menuitem_name: r.menuitem_name,
          median_time_to_ready_seconds: median_seconds,
          sample_size: sample_size,
          is_outlier: is_outlier,
        }
      end
    end
  end

  def voice_triggers
    cache_fetch('voice_triggers') do
      range = compute_range

      scope = VoiceCommand
        .joins(:smartmenu)
        .where(created_at: range)
        .where("(voice_commands.context ->> 'restaurant_id') = ?", @restaurant.id.to_s)

      if menu_id
        scope = scope.where("(voice_commands.context ->> 'menu_id') = ?", menu_id.to_s)
      end

      rows = scope
        .where("(voice_commands.intent ->> 'menuitem_id') IS NOT NULL")
        .joins("LEFT JOIN menuitems ON menuitems.id = ((voice_commands.intent ->> 'menuitem_id')::bigint)")
        .group("(voice_commands.intent ->> 'menuitem_id')", 'menuitems.name')
        .select(
          "(voice_commands.intent ->> 'menuitem_id')::bigint AS menuitem_id",
          "COALESCE(menuitems.name, 'Item') AS menuitem_name",
          'COUNT(*) AS voice_trigger_count',
          "SUM(CASE WHEN voice_commands.status = 'completed' THEN 1 ELSE 0 END) AS success_count",
          "SUM(CASE WHEN voice_commands.status = 'failed' THEN 1 ELSE 0 END) AS failure_count",
        )
        .order(Arel.sql('voice_trigger_count DESC'))

      rows.map do |r|
        success = r.success_count.to_i
        failure = r.failure_count.to_i
        denom = success + failure
        {
          menuitem_id: r.menuitem_id.to_i,
          menuitem_name: r.menuitem_name,
          voice_trigger_count: r.voice_trigger_count.to_i,
          success_count: success,
          failure_count: failure,
          success_rate: denom.positive? ? (success.to_f / denom) : 0.0,
        }
      end
    end
  end

  def abandonment_funnel
    cache_fetch('abandonment_funnel') do
      range = compute_range
      orders = filtered_orders(range)

      order_submitted = orders.where.not(orderedAt: nil).count
      bill_requested = orders.where.not(billRequestedAt: nil).count
      payment_succeeded = orders.where.not(paidAt: nil).count

      steps = [
        { step_key: 'order_submitted', step_count: order_submitted },
        { step_key: 'bill_requested', step_count: bill_requested },
        { step_key: 'payment_succeeded', step_count: payment_succeeded },
      ]

      previous = nil
      steps.map do |s|
        current = s[:step_count].to_i
        dropoff_count = previous.nil? ? 0 : [previous - current, 0].max
        dropoff_rate = previous.to_i.positive? ? (dropoff_count.to_f / previous) : 0.0
        previous = current

        s.merge(dropoff_count: dropoff_count, dropoff_rate: dropoff_rate)
      end
    end
  end

  private

  def cache_fetch(section, &)
    range = (@params[:range].presence || 'last28').to_s
    start_param = @params[:start].to_s
    end_param = @params[:end].to_s
    key = [
      'restaurant_insights',
      @restaurant.id,
      section,
      range,
      menu_id,
      start_param,
      end_param,
    ].join(':')

    Rails.cache.fetch(key, expires_in: 15.minutes, &)
  end

  def menu_id
    v = @params[:menu_id].presence
    v&.to_i
  end

  def compute_range
    rng = (@params[:range].presence || 'last28').to_s
    now = Time.zone.now

    case rng
    when 'today'
      cs = now.beginning_of_day
      ce = now.end_of_day
    when 'yesterday'
      cs = 1.day.ago.beginning_of_day
      ce = 1.day.ago.end_of_day
    when 'last7'
      cs = 6.days.ago.beginning_of_day
      ce = now.end_of_day
    when 'mtd'
      cs = now.beginning_of_month
      ce = now.end_of_day
    when 'last_month'
      cs = now.last_month.beginning_of_month
      ce = now.last_month.end_of_month
    when 'custom'
      begin
        cs = Time.zone.parse(@params[:start].to_s).beginning_of_day
        ce = Time.zone.parse(@params[:end].to_s).end_of_day
      rescue StandardError
        cs = 27.days.ago.beginning_of_day
        ce = now.end_of_day
      end
    else
      cs = 27.days.ago.beginning_of_day
      ce = now.end_of_day
    end

    cs..ce
  end

  def filtered_orders(range)
    scope = Ordr.where(restaurant_id: @restaurant.id, created_at: range)
    scope = scope.where(menu_id: menu_id) if menu_id
    scope.where.not(status: Ordr.statuses[:opened])
  end

  def restaurant_level_median_seconds(orders)
    row = OrdrStationTicket
      .joins(:ordr)
      .where(ordr_id: orders.select(:id))
      .where.not(submitted_at: nil)
      .where(status: [OrdrStationTicket.statuses[:ready], OrdrStationTicket.statuses[:collected]])
      .select('PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (ordr_station_tickets.updated_at - COALESCE(ordr_station_tickets.submitted_at, ordrs."orderedAt", ordrs.created_at)))) AS median_seconds')
      .take

    row&.median_seconds.to_f
  rescue StandardError
    0.0
  end
end
