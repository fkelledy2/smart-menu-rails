require 'csv'

class RestaurantAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_restaurant
  after_action :verify_authorized

  # Lightweight v0 endpoints to unblock UI wiring. Return shapes only.
  def kpis
    authorize @restaurant, :show?
    range = compute_range
    current_scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])
    previous_scope = filtered_orders.where(created_at: range[:previous_start]..range[:previous_end])

    k = compute_kpis(current_scope)
    p = compute_kpis(previous_scope)

    deltas = percentage_deltas(k, p)

    render json: { period: period_payload.merge(range), kpis: k, deltas: deltas }
  end

  def timeseries
    authorize @restaurant, :show?
    range = compute_range
    scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])

    # Daily buckets (works across typical ranges). Use DATE(created_at) for PG/MySQL.
    rows = scope
      .group('DATE(created_at)')
      .select('DATE(created_at) AS day, COALESCE(SUM(nett),0) AS net, COALESCE(SUM(tax),0) AS tax, COALESCE(SUM(service),0) AS service, COALESCE(SUM(tip),0) AS tip, COALESCE(SUM(gross),0) AS gross, COUNT(*) AS orders')
      .order(:day)

    series = rows.map do |r|
      { t: r.day.to_date.iso8601, gross: r.gross.to_f, net: r.net.to_f, orders: r.orders.to_i }
    end

    render json: { period: period_payload.merge(range), series: series }
  end

  def menu_mix
    authorize @restaurant, :show?
    range = compute_range
    scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])
    rows = scope
      .joins(:menu)
      .group('menus.id', 'menus.name')
      .select('menus.id AS menu_id, menus.name AS menu_name, COALESCE(SUM(ordrs.gross),0) AS revenue, COUNT(*) AS orders')
      .order(revenue: :desc)
    data = rows.map { |r| { menu_id: r.menu_id, menu_name: r.menu_name, revenue: r.revenue.to_f, orders: r.orders.to_i } }
    render json: { period: period_payload.merge(range), data: data }
  end

  def top_items
    authorize @restaurant, :show?
    range = compute_range
    scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])
    # Aggregate across ordritems
    rows = Ordritem.joins(:ordr)
      .joins('LEFT JOIN menuitems ON menuitems.id = ordritems.menuitem_id')
      .joins('LEFT JOIN menus ON menus.id = ordrs.menu_id')
      .where(ordrs: { id: scope.select(:id) })
      .group('ordritems.menuitem_id', 'menuitems.name', 'menus.id', 'menus.name')
      .select('ordritems.menuitem_id AS item_id, COALESCE(menuitems.name, \'Item\') AS item_name, COUNT(*) AS qty, COALESCE(SUM(ordritems.ordritemprice),0) AS revenue, menus.id AS menu_id, menus.name AS menu_name')
      .order(revenue: :desc, qty: :desc)
      .limit(12)
    data = rows.map { |r| { item_id: r.item_id, item_name: r.item_name, qty: r.qty.to_i, revenue: r.revenue.to_f, menu_id: r.menu_id, menu_name: r.menu_name } }
    render json: { period: period_payload.merge(range), data: data }
  end

  def staff_performance
    authorize @restaurant, :show?
    range = compute_range
    scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])
    rows = scope
      .joins('LEFT JOIN employees ON employees.id = ordrs.employee_id')
      .joins('LEFT JOIN users ON users.id = employees.user_id')
      .group('ordrs.employee_id', 'users.email')
      .select("ordrs.employee_id AS employee_id, COALESCE(users.email, ('#' || ordrs.employee_id::text)) AS employee_name, COALESCE(SUM(ordrs.gross),0) AS revenue, COUNT(*) AS orders")
      .order(revenue: :desc, orders: :desc)
    data = rows.map { |r| { employee_id: r.employee_id, employee_name: r.employee_name, revenue: r.revenue.to_f, orders: r.orders.to_i } }
    render json: { period: period_payload.merge(range), data: data }
  end

  def table_performance
    authorize @restaurant, :show?
    range = compute_range
    scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])
    rows = scope
      .joins(:tablesetting)
      .group('tablesettings.id', 'tablesettings.name')
      .select('tablesettings.id AS table_id, tablesettings.name AS table_name, COALESCE(SUM(ordrs.gross),0) AS revenue, COUNT(*) AS orders')
      .order(revenue: :desc, orders: :desc)
    data = rows.map { |r| { table_id: r.table_id, table_name: r.table_name, revenue: r.revenue.to_f, orders: r.orders.to_i } }
    render json: { period: period_payload.merge(range), data: data }
  end

  def orders
    authorize @restaurant, :show?
    range = compute_range
    scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])

    # Sorting
    sort = params[:sort].presence&.to_s
    dir  = params[:dir].to_s.upcase == 'ASC' ? 'ASC' : 'DESC'
    allowed_order_cols = {
      'created_at' => 'ordrs.created_at',
      'status' => 'ordrs.status',
      'gross' => 'ordrs.gross',
      'nett' => 'ordrs.nett',
      'tax' => 'ordrs.tax',
      'service' => 'ordrs.service',
      'tip' => 'ordrs.tip',
    }
    order_sql = allowed_order_cols[sort] || 'ordrs.created_at'

    # Pagination
    page = params[:page].to_i
    page = 1 if page <= 0
    per = params[:per].to_i
    per = 20 if per <= 0 || per > 200
    total_count = scope.count
    total_pages = (total_count.to_f / per).ceil
    offset = (page - 1) * per

    rows_sql = scope
      .left_joins(:menu, :tablesetting)
      .joins('LEFT JOIN employees ON employees.id = ordrs.employee_id')
      .joins('LEFT JOIN users ON users.id = employees.user_id')
      .order(Arel.sql("#{order_sql} #{dir}"))
      .limit(per)
      .offset(offset)
      .select('ordrs.id, ordrs.created_at, ordrs.status, ordrs.nett, ordrs.tax, ordrs.service, ordrs.tip, ordrs.gross, menus.name AS menu_name, tablesettings.name AS table_name, users.email AS employee_email')

    rows = rows_sql.map do |r|
      {
        id: r.id,
        created_at: r.created_at,
        status: Ordr.statuses.key(r.status) || r.status,
        net: r.nett.to_f,
        tax: r.tax.to_f,
        service: r.service.to_f,
        tip: r.tip.to_f,
        gross: r.gross.to_f,
        menu: r.menu_name,
        table: r.table_name,
        employee: r.employee_email,
      }
    end

    respond_to do |format|
      format.json do
        render json: {
          period: period_payload.merge(range),
          rows: rows,
          pagination: { page: page, per: per, total_pages: total_pages, total_count: total_count },
        }
      end
      format.csv do
        csv = CSV.generate(headers: true) do |c|
          c << %w[id created_at status menu table employee net tax service tip gross]
          rows.each do |row|
            c << [row[:id], row[:created_at], row[:status], row[:menu], row[:table], row[:employee], row[:net], row[:tax], row[:service], row[:tip], row[:gross]]
          end
        end
        send_data csv, filename: "orders_#{Time.zone.today}.csv"
      end
    end
  end

  def items
    authorize @restaurant, :show?
    range = compute_range
    scope = filtered_orders.where(created_at: range[:current_start]..range[:current_end])

    # Sorting
    sort = params[:sort].presence&.to_s
    dir  = params[:dir].to_s.upcase == 'ASC' ? 'ASC' : 'DESC'
    allowed_item_cols = {
      'created_at' => 'ordritems.created_at',
      'revenue' => 'ordritems.ordritemprice',
      'ordr_id' => 'ordritems.ordr_id',
    }
    order_sql = allowed_item_cols[sort] || 'ordritems.created_at'

    # Pagination
    page = params[:page].to_i
    page = 1 if page <= 0
    per = params[:per].to_i
    per = 20 if per <= 0 || per > 200

    base = Ordritem.joins(:ordr)
      .joins('LEFT JOIN menuitems ON menuitems.id = ordritems.menuitem_id')
      .where(ordrs: { id: scope.select(:id) })

    total_count = base.count
    total_pages = (total_count.to_f / per).ceil
    offset = (page - 1) * per

    rows_sql = base
      .order(Arel.sql("#{order_sql} #{dir}"))
      .limit(per)
      .offset(offset)
      .select('ordritems.id, ordritems.ordr_id, ordritems.created_at, menuitems.name AS item_name, ordritems.ordritemprice AS price')

    rows = rows_sql.map do |r|
      { id: r.id, ordr_id: r.ordr_id, created_at: r.created_at, item: r.item_name, revenue: r.price.to_f }
    end

    respond_to do |format|
      format.json do
        render json: {
          period: period_payload.merge(range),
          rows: rows,
          pagination: { page: page, per: per, total_pages: total_pages, total_count: total_count },
        }
      end
      format.csv do
        csv = CSV.generate(headers: true) do |c|
          c << %w[id ordr_id created_at item revenue]
          rows.each do |row|
            c << [row[:id], row[:ordr_id], row[:created_at], row[:item], row[:revenue]]
          end
        end
        send_data csv, filename: "items_#{Time.zone.today}.csv"
      end
    end
  end

  private

  def set_restaurant
    @restaurant = Restaurant.find(params[:id])
  end

  # Extract/filter params for date range, menu/employee/table/status filters
  def period_payload
    {
      range: params[:range].presence || 'last28',
      start: params[:start],
      end: params[:end],
      compare: ActiveModel::Type::Boolean.new.cast(params[:compare]),
    }
  end

  def compute_range
    # Returns current_start, current_end, previous_start, previous_end (Time.zone)
    rng = (params[:range].presence || 'last28').to_s
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
        cs = Time.zone.parse(params[:start].to_s).beginning_of_day
        ce = Time.zone.parse(params[:end].to_s).end_of_day
      rescue StandardError
        cs = 27.days.ago.beginning_of_day
        ce = now.end_of_day
      end
    else # 'last28'
      cs = 27.days.ago.beginning_of_day
      ce = now.end_of_day
    end

    days = ((ce.to_date - cs.to_date).to_i + 1).clamp(1, 400)
    ps = (cs - days.days)
    pe = (ce - days.days)

    { current_start: cs, current_end: ce, previous_start: ps, previous_end: pe }
  end

  def filtered_orders
    scope = Ordr.where(restaurant_id: @restaurant.id)
    if params[:menu_id].present?
      scope = scope.where(menu_id: params[:menu_id])
    end
    if params[:employee_id].present?
      scope = scope.where(employee_id: params[:employee_id])
    end
    if params[:table_id].present?
      scope = scope.where(tablesetting_id: params[:table_id])
    end
    if params[:status].present? && params[:status] != 'all'
      # Support UI-friendly filters and enum/numeric values
      case params[:status].to_s
      when 'open'
        # All non-final states
        open_keys = %w[opened ordered preparing ready delivered billrequested]
        scope = scope.where(status: open_keys.map { |k| Ordr.statuses[k] })
      when 'completed'
        # Completed/closed revenue-impacting states
        done_keys = %w[paid closed]
        scope = scope.where(status: done_keys.map { |k| Ordr.statuses[k] })
      when 'cancelled', 'canceled'
        # No explicit cancelled state exists; return none
        scope = scope.none
      else
        # Allow either symbolic or integer status mapping
        value = Ordr.statuses[params[:status]] || params[:status]
        scope = scope.where(status: value)
      end
    end
    scope
  end

  def compute_kpis(scope)
    # Use pick to avoid nil object method calls; default to zero values
    net, tax, service, tip, gross, orders = scope.pick(
      Arel.sql('COALESCE(SUM(nett),0)'),
      Arel.sql('COALESCE(SUM(tax),0)'),
      Arel.sql('COALESCE(SUM(service),0)'),
      Arel.sql('COALESCE(SUM(tip),0)'),
      Arel.sql('COALESCE(SUM(gross),0)'),
      Arel.sql('COUNT(*)'),
    )

    net ||= 0.0
    tax ||= 0.0
    service ||= 0.0
    tip ||= 0.0
    gross ||= 0.0
    orders ||= 0
    items_count = Ordritem.where(ordr_id: scope.select(:id)).count
    aov = orders.to_i.positive? ? (gross.to_f / orders.to_i) : 0.0
    {
      gross: gross.to_f,
      net: net.to_f,
      taxes: tax.to_f,
      tips: tip.to_f,
      service: service.to_f,
      orders: orders.to_i,
      items: items_count,
      aov: aov,
    }
  end

  def percentage_deltas(current, previous)
    keys = %i[gross net taxes tips service orders items aov]
    deltas = {}
    keys.each do |k|
      cur = current[k].to_f
      prev = previous[k].to_f
      deltas[k] = if prev.zero?
                    0.0
                  else
                    ((cur - prev) / prev.to_f) * 100.0
                  end
    end
    deltas
  end
end
