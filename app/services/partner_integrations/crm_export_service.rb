# frozen_string_literal: true

module PartnerIntegrations
  # Computes CRM signals for a restaurant over a configurable window.
  # Provides per-order behavioural signals useful for guest profile enrichment.
  #
  # Signals:
  #   - order_pacing: per-order summary with time-to-first-item, time-to-bill, total session
  #   - avg_time_to_bill_seconds: mean time from order creation to billRequestedAt
  #   - avg_session_duration_seconds: mean time from creation to paidAt
  #   - repeat_table_count: tables that have had more than one order in the window
  class CrmExportService
    DEFAULT_WINDOW_MINUTES = 60

    def initialize(restaurant:, window_minutes: DEFAULT_WINDOW_MINUTES)
      @restaurant     = restaurant
      @window_minutes = window_minutes.to_i.clamp(1, 1440)
      @window_start   = @window_minutes.minutes.ago
    end

    def call
      {
        restaurant_id: @restaurant.id,
        window_minutes: @window_minutes,
        generated_at: Time.zone.now.iso8601,
        avg_time_to_bill_seconds: avg_time_to_bill_seconds,
        avg_session_duration_seconds: avg_session_duration_seconds,
        repeat_table_count: repeat_table_count,
        order_pacing: order_pacing,
      }
    end

    private

    def recent_ordrs
      @recent_ordrs ||= Ordr
        .where(restaurant_id: @restaurant.id)
        .where(created_at: @window_start..)
    end

    # Mean seconds from order creation → billRequestedAt
    def avg_time_to_bill_seconds
      rows = recent_ordrs
        .where.not(billRequestedAt: nil)
        .pluck(:created_at, :billRequestedAt)
      return nil if rows.empty?

      total = rows.sum { |created, billed| (billed - created).to_f }
      (total / rows.size).round(1)
    end

    # Mean seconds from order creation → paidAt
    def avg_session_duration_seconds
      rows = recent_ordrs
        .where.not(paidAt: nil)
        .pluck(:created_at, :paidAt)
      return nil if rows.empty?

      total = rows.sum { |created, paid| (paid - created).to_f }
      (total / rows.size).round(1)
    end

    # Number of tables that saw more than one order in the window
    def repeat_table_count
      recent_ordrs
        .group(:tablesetting_id)
        .having('COUNT(*) > 1')
        .count
        .size
    end

    # Per-order pacing signals (capped at 200 records for API response size)
    def order_pacing
      recent_ordrs
        .order(created_at: :desc)
        .limit(200)
        .pluck(:id, :tablesetting_id, :created_at, :orderedAt, :billRequestedAt, :paidAt, :gross)
        .map { |row| build_pacing_entry(row) }
    end

    def build_pacing_entry(row)
      id, tablesetting_id, created, ordered, billed, paid, gross = row
      {
        order_id: id,
        tablesetting_id: tablesetting_id,
        opened_at: created&.iso8601,
        first_item_at: ordered&.iso8601,
        bill_requested_at: billed&.iso8601,
        paid_at: paid&.iso8601,
        time_to_first_item_seconds: ordered ? (ordered - created).to_i : nil,
        time_to_bill_seconds: billed ? (billed - created).to_i : nil,
        session_duration_seconds: paid ? (paid - created).to_i : nil,
        gross_amount: gross,
      }.compact
    end
  end
end
