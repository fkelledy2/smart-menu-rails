# frozen_string_literal: true

module PartnerIntegrations
  # Computes workforce signals for a restaurant over a configurable window.
  # Queries are read-only and constrained to the 15s replica statement timeout.
  #
  # Signals:
  #   - order_velocity: orders per minute over the last N minutes
  #   - avg_prep_time_seconds: mean time from order creation to paidAt (proxy for
  #     full service cycle) for closed orders in the window
  #   - table_occupancy: per-table duration summaries for occupied tables
  #   - top_items: most-ordered menu items by quantity in the window (for staffing)
  class WorkforceExportService
    DEFAULT_WINDOW_MINUTES = 60

    def initialize(restaurant:, window_minutes: DEFAULT_WINDOW_MINUTES)
      @restaurant     = restaurant
      @window_minutes = window_minutes.to_i.clamp(1, 1440) # max 24 hours
      @window_start   = window_minutes.minutes.ago
    end

    def call
      {
        restaurant_id: @restaurant.id,
        window_minutes: @window_minutes,
        generated_at: Time.zone.now.iso8601,
        order_velocity: order_velocity,
        avg_prep_time_seconds: avg_prep_time_seconds,
        table_occupancy: table_occupancy,
        top_items: top_items,
      }
    end

    private

    def recent_ordrs
      @recent_ordrs ||= Ordr
        .where(restaurant_id: @restaurant.id)
        .where(created_at: @window_start..)
    end

    def closed_ordrs
      @closed_ordrs ||= recent_ordrs.where(status: Ordr.statuses['closed'])
    end

    # Orders per minute over the window
    def order_velocity
      count = recent_ordrs.count
      return 0.0 if @window_minutes.zero?

      (count.to_f / @window_minutes).round(4)
    end

    # Mean seconds from order creation → paidAt for closed orders in the window.
    # Falls back to created_at → updated_at if paidAt is not populated.
    def avg_prep_time_seconds
      rows = closed_ordrs.where.not(paidAt: nil).pluck(:created_at, :paidAt)
      return nil if rows.empty?

      total = rows.sum { |created, paid| (paid - created).to_f }
      (total / rows.size).round(1)
    end

    # Per-table occupancy: currently occupied tables with session start time
    def table_occupancy
      occupied_tables = Tablesetting
        .where(restaurant_id: @restaurant.id, status: Tablesetting.statuses['occupied'])
        .select(:id, :name, :updated_at)

      occupied_tables.map do |table|
        duration = (Time.zone.now - table.updated_at).to_i
        {
          tablesetting_id: table.id,
          name: table.name,
          occupied_since: table.updated_at.iso8601,
          duration_seconds: duration,
        }
      end
    end

    # Top 10 menu items by quantity ordered in the window
    def top_items
      Ordritem
        .joins(:ordr)
        .where(ordrs: { restaurant_id: @restaurant.id })
        .where(ordrs: { created_at: @window_start.. })
        .group(:menuitem_id)
        .order(Arel.sql('SUM(ordritems.quantity) DESC'))
        .limit(10)
        .sum('ordritems.quantity')
        .map { |menuitem_id, qty| { menuitem_id: menuitem_id, quantity_ordered: qty } }
    end
  end
end
