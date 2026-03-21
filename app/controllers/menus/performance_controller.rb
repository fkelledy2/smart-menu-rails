# frozen_string_literal: true

module Menus
  class PerformanceController < BaseController
    before_action :authenticate_user!
    before_action :set_menu
    after_action :verify_authorized, except: %i[performance]

    # GET /restaurants/:restaurant_id/menus/:id/performance
    def performance
      unless policy(@menu).performance?
        redirect_to restaurant_menus_path(@restaurant), alert: 'Access denied'
        return
      end

      days = params[:days]&.to_i || 30
      period_start = days.days.ago

      @performance_data = {
        menu: {
          id: @menu.id,
          name: @menu.name,
          restaurant_name: @menu.restaurant.name,
          created_at: @menu.created_at,
        },
        period: {
          days: days,
          start_date: period_start.strftime('%Y-%m-%d'),
          end_date: Date.current.strftime('%Y-%m-%d'),
        },
        cache_performance: collect_cache_performance,
        database_performance: collect_database_performance,
        response_times: collect_response_times,
        user_activity: collect_user_activity(days),
        system_metrics: collect_system_metrics,
      }

      AnalyticsService.track_user_event(current_user, 'menu_performance_viewed', {
        menu_id: @menu.id,
        restaurant_id: @menu.restaurant.id,
        period_days: days,
        cache_hit_rate: @performance_data[:cache_performance][:hit_rate],
        avg_response_time: @performance_data[:response_times][:average],
      })

      respond_to do |format|
        format.html
        format.json { render json: @performance_data }
      end
    rescue StandardError => e
      Rails.logger.error "[Menus::PerformanceController] Error collecting performance data: #{e.message}"
      head :internal_server_error
    end

    private

    def collect_cache_performance
      menu_performance = AdvancedCacheService.cached_menu_performance(@menu.id, 30)

      {
        hit_rate: menu_performance[:cache_stats][:hit_rate] || 0,
        total_hits: menu_performance[:cache_stats][:hits] || 0,
        total_misses: menu_performance[:cache_stats][:misses] || 0,
        total_operations: menu_performance[:cache_stats][:operations] || 0,
        last_reset: Time.current.iso8601,
      }
    rescue StandardError => e
      Rails.logger.error("[Menus::PerformanceController] Cache performance collection failed: #{e.message}")
      { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0, last_reset: Time.current.iso8601 }
    end

    def collect_database_performance
      {
        replica_lag: DatabaseRoutingService.replica_lag_ms || 0,
        connection_pool_usage: connection_pool_usage_pct,
      }
    rescue StandardError => e
      Rails.logger.error("[Menus::PerformanceController] Database performance collection failed: #{e.message}")
      { replica_lag: 0, connection_pool_usage: 0 }
    end

    def collect_response_times
      performance_summary = MenusController.cache_performance_summary(days: 30)
      menu_metrics = performance_summary['menus#show'] || {}

      {
        average: menu_metrics[:avg_time] || 0,
        maximum: menu_metrics[:max_time] || 0,
        request_count: menu_metrics[:count] || 0,
        cache_efficiency: menu_metrics[:avg_cache_hits] || 0,
      }
    rescue StandardError => e
      Rails.logger.error("[Menus::PerformanceController] Response time collection failed: #{e.message}")
      { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 }
    end

    def collect_user_activity(_days)
      {
        total_sessions: 0,
        unique_visitors: 0,
        page_views: 0,
        average_session_duration: 0,
        bounce_rate: 0,
      }
    rescue StandardError => e
      Rails.logger.error("[Menus::PerformanceController] User activity collection failed: #{e.message}")
      { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0, bounce_rate: 0 }
    end

    def collect_system_metrics
      {
        memory_usage_mb: (`ps -o rss= -p #{Process.pid}`.to_i / 1024),
        active_connections: ActiveRecord::Base.connection_pool.connections.count,
        connection_pool_usage: connection_pool_usage_pct,
      }
    rescue StandardError => e
      Rails.logger.error("[Menus::PerformanceController] System metrics collection failed: #{e.message}")
      { memory_usage_mb: 0, active_connections: 0, connection_pool_usage: 0 }
    end

    def connection_pool_usage_pct
      pool = ActiveRecord::Base.connection_pool
      ((pool.connections.count.to_f / pool.size) * 100).round(2)
    rescue StandardError
      0
    end
  end
end
