# frozen_string_literal: true

module Agents
  module Tools
    # Agents::Tools::ReadOrderAnalytics — read-only analytics query tool.
    #
    # Fetches order summary stats for a restaurant over a specified period.
    # Uses the read replica DB. Returns a structured hash suitable for table
    # formatting or narrative generation.
    #
    # Params:
    #   restaurant_id [Integer]
    #   period        [String]  — human-readable period: 'today', 'yesterday',
    #                             'last week', 'this week', 'this month', 'last month'
    #   item_name     [String]  — optional; filters stats to a single item if provided
    class ReadOrderAnalytics < BaseTool
      PERIOD_MAP = {
        'today' => -> { Time.current.all_day },
        'yesterday' => -> { 1.day.ago.all_day },
        'this week' => -> { Time.current.all_week },
        'last week' => -> { 1.week.ago.all_week },
        'this month' => -> { Time.current.all_month },
        'last month' => -> { 1.month.ago.all_month },
      }.freeze

      DEFAULT_PERIOD = 'last week'

      def self.tool_name
        'read_order_analytics'
      end

      def self.description
        'Read order analytics for a restaurant: total orders, revenue, average ticket, and top items.'
      end

      def self.input_schema
        {
          type: 'object',
          properties: {
            restaurant_id: { type: 'integer', description: 'Restaurant ID' },
            period: {
              type: 'string',
              description: "Time period: 'today', 'yesterday', 'this week', 'last week', 'this month', 'last month'",
            },
            item_name: {
              type: 'string',
              description: 'Optional — filter to stats for a specific item name',
            },
          },
          required: ['restaurant_id'],
        }
      end

      def self.call(params)
        new(params).call
      end

      def initialize(params)
        @restaurant_id = params['restaurant_id'] || params[:restaurant_id]
        @period        = normalise_period(params['period'] || params[:period] || DEFAULT_PERIOD)
        @item_name     = params['item_name'] || params[:item_name]
      end

      def call
        range = period_range

        # Use replica for analytics
        ActiveRecord::Base.connected_to(role: :reading) do
          build_analytics(range)
        end
      rescue ActiveRecord::StatementTimeout
        # Fall back to primary on timeout
        Rails.logger.warn('[ReadOrderAnalytics] Replica timeout — falling back to primary')
        build_analytics(period_range)
      end

      private

      def build_analytics(range)
        # Exclude draft/incomplete orders — only count ordered or further
        base_scope = Ordr
          .where(restaurant_id: @restaurant_id)
          .where(created_at: range)
          .where.not(status: Ordr.statuses[:opened])

        total_orders = base_scope.count

        # Revenue: sum of all ordritem line totals within these orders
        revenue_rows = Ordritem
          .joins(:ordr)
          .where(ordrs: { restaurant_id: @restaurant_id, created_at: range })
          .where.not(ordrs: { status: Ordr.statuses[:opened] })
          .where.not(ordritems: { status: Ordritem.statuses[:removed] })

        revenue_rows = revenue_rows.joins(:menuitem).where('menuitems.name ILIKE ?', "%#{@item_name}%") if @item_name.present?

        # ordritemprice is a float (price per item); quantity is integer
        total_revenue_cents = (revenue_rows.sum(Arel.sql('COALESCE(ordritems.quantity, 1) * COALESCE(ordritems.ordritemprice, 0)')) * 100).to_i
        avg_ticket_cents    = total_orders.positive? ? (total_revenue_cents / total_orders) : 0

        currency = restaurant_currency

        # Top items
        top_items = Ordritem
          .joins(:ordr, :menuitem)
          .where(ordrs: { restaurant_id: @restaurant_id, created_at: range })
          .where.not(ordrs: { status: Ordr.statuses[:opened] })
          .where.not(ordritems: { status: Ordritem.statuses[:removed] })
          .group('menuitems.id', 'menuitems.name')
          .select(
            'menuitems.id AS menuitem_id',
            'menuitems.name AS item_name',
            'COALESCE(SUM(ordritems.quantity), 0) AS quantity_sold',
          )
          .order(Arel.sql('quantity_sold DESC'))
          .limit(10)
          .map do |row|
            {
              id: row.menuitem_id,
              name: row.item_name,
              quantity_sold: row.quantity_sold.to_i,
              margin_pct: nil, # Phase 2: integrate ProfitMarginAnalyticsService
            }
          end

        {
          period: @period,
          total_orders: total_orders,
          total_revenue_cents: total_revenue_cents,
          total_revenue_formatted: format_cents(total_revenue_cents, currency),
          avg_ticket_cents: avg_ticket_cents,
          avg_ticket_formatted: format_cents(avg_ticket_cents, currency),
          top_items: top_items,
          orders: total_orders.positive? ? [true] : [], # sentinel for blank? check
        }
      end

      def period_range
        normalised = normalise_period(@period)
        lambda_fn  = PERIOD_MAP[normalised]
        lambda_fn ? lambda_fn.call : 1.week.ago..Time.current
      end

      def normalise_period(raw)
        return DEFAULT_PERIOD if raw.blank?

        lowered = raw.to_s.downcase.strip
        PERIOD_MAP.key?(lowered) ? lowered : DEFAULT_PERIOD
      end

      def restaurant_currency
        Restaurant.where(id: @restaurant_id).pick(:currency) || 'EUR'
      end

      def format_cents(cents, currency)
        symbol = currency_symbol(currency)
        "#{symbol}#{format('%.2f', cents.to_f / 100)}"
      end

      def currency_symbol(currency)
        case currency.to_s.upcase
        when 'EUR' then '€'
        when 'USD' then '$'
        when 'GBP' then '£'
        else '€'
        end
      end
    end
  end
end
