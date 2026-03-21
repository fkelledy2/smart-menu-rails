# frozen_string_literal: true

module Restaurants
  class PerformanceController < BaseController
    before_action :set_restaurant

    # GET /restaurants/:id/performance
    def performance
      unless @restaurant
        Rails.logger.error "[Restaurants::PerformanceController#performance] @restaurant is nil, params: #{params.inspect}"
        redirect_to restaurants_path, alert: 'Restaurant not found. Please select a restaurant first.'
        return
      end

      Rails.logger.debug { "[Restaurants::PerformanceController#performance] Processing performance for restaurant #{@restaurant.id}" }
      authorize @restaurant

      days = params[:days]&.to_i || 30
      period_start = days.days.ago

      @performance_data = {
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
        cache_performance: collect_cache_performance_data,
        database_performance: collect_database_performance_data,
        response_times: collect_response_time_data,
        user_activity: collect_user_activity_data(days),
        system_metrics: collect_system_metrics_data,
      }

      AnalyticsService.track_user_event(current_user, 'restaurant_performance_viewed', {
        restaurant_id: @restaurant.id,
        period_days: days,
        cache_hit_rate: @performance_data[:cache_performance][:hit_rate],
        avg_response_time: @performance_data[:response_times][:average],
      })

      respond_to do |format|
        format.html
        format.json { render json: @performance_data }
      end
    end

    private

    def collect_cache_performance_data
      cache_stats = AdvancedCacheService.cache_stats
      {
        hit_rate: cache_stats[:hit_rate] || 0,
        total_hits: cache_stats[:hits] || 0,
        total_misses: cache_stats[:misses] || 0,
        total_operations: cache_stats[:total_operations] || 0,
        last_reset: cache_stats[:last_reset],
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::PerformanceController] Cache performance data collection failed: #{e.message}")
      { hit_rate: 0, total_hits: 0, total_misses: 0, total_operations: 0, last_reset: Time.current.iso8601 }
    end

    def collect_database_performance_data
      {
        primary_queries: DatabaseRoutingService.primary_query_count || 0,
        replica_queries: DatabaseRoutingService.replica_query_count || 0,
        replica_lag: DatabaseRoutingService.replica_lag_ms || 0,
        connection_pool_usage: calculate_connection_pool_usage,
        slow_queries: 0,
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::PerformanceController] Database performance data collection failed: #{e.message}")
      { primary_queries: 0, replica_queries: 0, replica_lag: 0, connection_pool_usage: 0, slow_queries: 0 }
    end

    def collect_response_time_data
      performance_summary = begin
        self.class.cache_performance_summary(days: 30)
      rescue StandardError => e
        Rails.logger.warn("[Restaurants::PerformanceController] Failed to collect cache_performance_summary: #{e.message}")
        {}
      end
      restaurant_metrics = performance_summary['restaurants#show'] || {}

      {
        average: restaurant_metrics[:avg_time] || 0,
        maximum: restaurant_metrics[:max_time] || 0,
        request_count: restaurant_metrics[:count] || 0,
        cache_efficiency: restaurant_metrics[:avg_cache_hits] || 0,
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::PerformanceController] Response time data collection failed: #{e.message}")
      { average: 0, maximum: 0, request_count: 0, cache_efficiency: 0 }
    end

    def collect_user_activity_data(days)
      activity_data = AdvancedCacheService.cached_user_activity(current_user.id, days: days)

      {
        total_sessions: activity_data[:sessions][:total] || 0,
        unique_visitors: activity_data[:visitors][:unique] || 0,
        page_views: activity_data[:page_views][:total] || 0,
        average_session_duration: activity_data[:sessions][:avg_duration] || 0,
        bounce_rate: activity_data[:sessions][:bounce_rate] || 0,
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::PerformanceController] User activity data collection failed: #{e.message}")
      { total_sessions: 0, unique_visitors: 0, page_views: 0, average_session_duration: 0, bounce_rate: 0 }
    end

    def collect_system_metrics_data
      {
        memory_usage: (`ps -o rss= -p #{Process.pid}`.to_i / 1024),
        cpu_usage: 0,
        disk_usage: 0,
        active_connections: ActiveRecord::Base.connection_pool.connections.count,
        background_jobs: 0,
      }
    rescue StandardError => e
      Rails.logger.error("[Restaurants::PerformanceController] System metrics data collection failed: #{e.message}")
      { memory_usage: 0, cpu_usage: 0, disk_usage: 0, active_connections: 0, background_jobs: 0 }
    end

    def calculate_connection_pool_usage
      pool = ActiveRecord::Base.connection_pool
      ((pool.connections.count.to_f / pool.size) * 100).round(2)
    rescue StandardError
      0
    end
  end
end
