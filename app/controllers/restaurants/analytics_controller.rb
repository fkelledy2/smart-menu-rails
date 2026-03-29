# frozen_string_literal: true

module Restaurants
  class AnalyticsController < BaseController
    before_action :set_restaurant

    # GET /restaurants/:id/analytics
    def analytics
      unless @restaurant
        Rails.logger.error "[Restaurants::AnalyticsController#analytics] @restaurant is nil, params: #{params.inspect}"
        redirect_to restaurants_path, alert: 'Restaurant not found. Please select a restaurant first.'
        return
      end

      Rails.logger.debug { "[Restaurants::AnalyticsController#analytics] Processing analytics for restaurant #{@restaurant.id}" }
      authorize @restaurant

      days = params[:days]&.to_i || 30
      period_start = days.days.ago

      begin
        @analytics_data = {
          restaurant: {
            id: @restaurant.id,
            name: @restaurant.name,
            created_at: @restaurant.created_at,
          },
          period: {
            days: days,
            start_date: period_start.strftime('%Y-%m-%d'),
            end_date: Date.current.strftime('%Y-%m-%d'),
          },
          orders: collect_order_analytics_data(days),
          revenue: collect_revenue_analytics_data(days),
          customers: collect_customer_analytics_data(days),
          menu_items: collect_menu_item_analytics_data(days),
          traffic: collect_traffic_analytics_data(days),
          trends: collect_trend_analytics_data(days),
        }
      rescue StandardError => e
        Rails.logger.error "[Restaurants::AnalyticsController#analytics] Error collecting analytics data: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")

        @analytics_data = {
          restaurant: {
            id: @restaurant.id,
            name: @restaurant.name,
            created_at: @restaurant.created_at,
          },
          period: {
            days: days,
            start_date: period_start.strftime('%Y-%m-%d'),
            end_date: Date.current.strftime('%Y-%m-%d'),
          },
          orders: { total: 0, completed: 0, cancelled: 0, pending: 0, daily_data: [] },
          revenue: { total: 0, average_order: 0, daily_data: [], top_items: [] },
          customers: { total: 0, new: 0, returning: 0, daily_data: [] },
          menu_items: { total: 0, most_popular: [], least_popular: [] },
          traffic: { page_views: 0, unique_visitors: 0, bounce_rate: 0, daily_data: [] },
          trends: { growth_rate: 0, seasonal_patterns: [], peak_hours: [] },
        }
      end

      AnalyticsService.track_user_event(current_user, 'restaurant_analytics_viewed', {
        restaurant_id: @restaurant.id,
        period_days: days,
        total_orders: @analytics_data[:orders][:total],
        total_revenue: @analytics_data[:revenue][:total],
      })

      respond_to do |format|
        format.html
        format.json { render json: @analytics_data }
      end
    end

    # GET /restaurants/:id/user_activity
    def user_activity
      authorize @restaurant

      days = params[:days]&.to_i || 7
      @activity_data = AdvancedCacheService.cached_user_activity(current_user.id, days: days)

      respond_to do |format|
        format.html
        format.json { render json: @activity_data }
      end
    end

    private

    def collect_order_analytics_data(days)
      period_start = days.days.ago
      orders = @restaurant.ordrs.where(created_at: period_start..Time.current)

      # Ordr status enum: opened=0, ordered=20, preparing=22, ready=24,
      # delivered=25, billrequested=30, paid=35, closed=40
      # 'cancelled', 'open', 'pending' do not exist as enum values and would
      # silently return 0 rows. Use the correct status key strings.
      open_statuses = Ordr.statuses.slice('opened', 'ordered', 'preparing', 'ready', 'delivered', 'billrequested').values
      {
        total: orders.count,
        completed: orders.where(status: Ordr.statuses['closed']).count,
        cancelled: 0, # No cancelled state exists in the Ordr enum
        pending: orders.where(status: open_statuses).count,
        daily_data: generate_daily_order_data(orders, days),
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::AnalyticsController] Order analytics data collection failed: #{e.message}")
      { total: 0, completed: 0, cancelled: 0, pending: 0, daily_data: [] }
    end

    def collect_revenue_analytics_data(days)
      period_start = days.days.ago
      orders = @restaurant.ordrs.where(created_at: period_start..Time.current, status: 'closed')

      total_revenue = orders.sum(:gross) || 0
      order_count = orders.count
      average_order = order_count.positive? ? (total_revenue / order_count).round(2) : 0

      {
        total: total_revenue,
        average_order: average_order,
        daily_data: generate_daily_revenue_data(orders, days),
        top_items: get_top_selling_items(days),
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::AnalyticsController] Revenue analytics data collection failed: #{e.message}")
      { total: 0, average_order: 0, daily_data: [], top_items: [] }
    end

    def collect_customer_analytics_data(days)
      period_start = days.days.ago
      orders = @restaurant.ordrs.where(created_at: period_start..Time.current)

      participants = Ordrparticipant.joins(:ordr)
        .where(ordrs: { restaurant_id: @restaurant.id, created_at: period_start..Time.current })
        .where.not(sessionid: [nil, ''])

      total_customers = participants.distinct.count(:sessionid)
      total_customers = orders.distinct.count(:tablesetting_id) if total_customers.zero?

      if participants.any?
        current_period_sessions = participants.distinct.pluck(:sessionid)

        # Count how many current-period sessions also appeared in the prior period.
        # Use a bounded lookback (6× the current window, max 365 days) to avoid
        # an unbounded pluck of the entire historical participant table.
        lookback_start = [period_start - (days * 6).days, 365.days.ago].max
        returning_count = Ordrparticipant.joins(:ordr)
          .where(ordrs: { restaurant_id: @restaurant.id })
          .where(ordrs: { created_at: lookback_start...period_start })
          .where(sessionid: current_period_sessions)
          .where.not(sessionid: [nil, ''])
          .distinct.count(:sessionid)

        new_customers = current_period_sessions.size - returning_count
      else
        new_customers = (total_customers * 0.7).round
      end
      returning_customers = total_customers - new_customers

      {
        total: total_customers,
        new: new_customers,
        returning: returning_customers,
        daily_data: generate_daily_customer_data(orders, days),
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::AnalyticsController] Customer analytics data collection failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      { total: 0, new: 0, returning: 0, daily_data: [] }
    end

    def collect_menu_item_analytics_data(days)
      period_start = days.days.ago

      order_items = Ordritem.joins(:ordr)
        .where(ordrs: { restaurant_id: @restaurant.id, created_at: period_start..Time.current })

      item_counts = order_items.group(:menuitem_id).count

      # Bulk-load all relevant menuitems in a single query to avoid N+1
      menuitem_ids = item_counts.keys.compact
      menuitem_names = Menuitem.where(id: menuitem_ids).pluck(:id, :name).to_h

      sorted_asc  = item_counts.sort_by { |_, count| count }
      sorted_desc = sorted_asc.reverse

      most_popular = sorted_desc.first(5).map do |menuitem_id, count|
        { name: menuitem_names[menuitem_id] || 'Unknown', count: count }
      end

      least_popular = sorted_asc.first(5).map do |menuitem_id, count|
        { name: menuitem_names[menuitem_id] || 'Unknown', count: count }
      end

      {
        total: @restaurant.menus.joins(:menuitems).count,
        most_popular: most_popular,
        least_popular: least_popular,
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::AnalyticsController] Menu item analytics data collection failed: #{e.message}")
      { total: 0, most_popular: [], least_popular: [] }
    end

    def collect_traffic_analytics_data(days)
      # TODO: wire up real traffic analytics (e.g. Plausible/GA integration)
      {
        page_views: 0,
        unique_visitors: 0,
        bounce_rate: 0,
        daily_data: generate_daily_traffic_data(days),
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::AnalyticsController] Traffic analytics data collection failed: #{e.message}")
      { page_views: 0, unique_visitors: 0, bounce_rate: 0, daily_data: [] }
    end

    def collect_trend_analytics_data(days)
      current_period_orders = @restaurant.ordrs.where(created_at: days.days.ago..Time.current).count
      previous_period_orders = @restaurant.ordrs.where(created_at: (days * 2).days.ago..days.days.ago).count

      growth_rate = if previous_period_orders.positive?
                      ((current_period_orders - previous_period_orders).to_f / previous_period_orders * 100).round(2)
                    else
                      0
                    end

      {
        growth_rate: growth_rate,
        seasonal_patterns: generate_seasonal_patterns,
        peak_hours: generate_peak_hours_data,
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::AnalyticsController] Trend analytics data collection failed: #{e.message}")
      { growth_rate: 0, seasonal_patterns: [], peak_hours: [] }
    end

    def generate_daily_order_data(orders, days)
      (0...days).map do |i|
        date = i.days.ago.to_date
        { date: date.strftime('%Y-%m-%d'), value: orders.where(created_at: date.all_day).count }
      end.reverse
    end

    def generate_daily_revenue_data(orders, days)
      (0...days).map do |i|
        date = i.days.ago.to_date
        { date: date.strftime('%Y-%m-%d'), value: orders.where(created_at: date.all_day).sum(:gross) || 0 }
      end.reverse
    end

    def generate_daily_customer_data(orders, days)
      (0...days).map do |i|
        date = i.days.ago.to_date
        daily_orders = orders.where(created_at: date.all_day)

        daily_participants = Ordrparticipant.joins(:ordr)
          .where(ordrs: { id: daily_orders.select(:id) })
          .where.not(sessionid: [nil, ''])

        customers = daily_participants.distinct.count(:sessionid)
        customers = daily_orders.distinct.count(:tablesetting_id) if customers.zero? && daily_orders.any?

        { date: date.strftime('%Y-%m-%d'), value: customers }
      end.reverse
    end

    def generate_daily_traffic_data(days)
      # Traffic analytics not yet wired to a real data source.
      # Return zeros rather than rand() which produces misleading fake data on every request.
      (0...days).map do |i|
        date = i.days.ago.to_date
        { date: date.strftime('%Y-%m-%d'), value: 0 }
      end.reverse
    end

    def get_top_selling_items(days)
      period_start = days.days.ago

      item_counts = Ordritem.joins(:ordr, :menuitem)
        .where(ordrs: { restaurant_id: @restaurant.id, created_at: period_start..Time.current })
        .group('menuitems.name')
        .count

      item_counts.sort_by { |_, count| -count }
        .first(5)
        .map { |name, count| { name: name, quantity: count } }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::AnalyticsController] Top selling items collection failed: #{e.message}")
      []
    end

    def generate_seasonal_patterns
      # TODO: wire up real seasonal pattern analysis
      ['Monday Peak', 'Weekend Rush', 'Lunch Hour Boost'].map do |pattern|
        { pattern: pattern, impact: 0 }
      end
    end

    def generate_peak_hours_data
      # TODO: wire up real peak-hour order counts from DB
      (0..23).map { |hour| { hour: hour, orders: 0 } }
    end
  end
end
