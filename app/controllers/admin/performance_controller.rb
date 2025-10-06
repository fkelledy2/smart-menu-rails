# frozen_string_literal: true

class Admin::PerformanceController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  
  # Pundit authorization
  after_action :verify_authorized

  # GET /admin/performance
  def index
    authorize [:admin, :performance]
    
    @metrics = PerformanceMonitoringService.get_metrics
    @request_stats = PerformanceMonitoringService.get_request_stats
    @slow_queries = PerformanceMonitoringService.get_slow_queries
    
    respond_to do |format|
      format.html
      format.json { render json: { metrics: @metrics, request_stats: @request_stats, slow_queries: @slow_queries } }
    end
  end

  # GET /admin/performance/requests
  def requests
    authorize [:admin, :performance], :show?
    
    @request_stats = PerformanceMonitoringService.get_request_stats
    @recent_requests = PerformanceMonitoringService.get_metrics[:requests]
    
    respond_to do |format|
      format.html { render :requests }
      format.json { render json: { request_stats: @request_stats, recent_requests: @recent_requests } }
    end
  end

  # GET /admin/performance/queries
  def queries
    authorize [:admin, :performance], :show?
    
    @slow_queries = PerformanceMonitoringService.get_slow_queries(limit: 50)
    @recent_queries = PerformanceMonitoringService.get_metrics[:queries]
    
    respond_to do |format|
      format.html { render :queries }
      format.json { render json: { slow_queries: @slow_queries, recent_queries: @recent_queries } }
    end
  end

  # GET /admin/performance/cache
  def cache
    authorize [:admin, :performance], :show?
    
    @cache_stats = PerformanceMonitoringService.get_metrics[:cache_stats]
    @advanced_cache_info = AdvancedCacheService.cache_info
    @advanced_cache_stats = AdvancedCacheService.cache_stats
    
    respond_to do |format|
      format.html { render :cache }
      format.json { render json: { cache_stats: @cache_stats, advanced_cache: @advanced_cache_stats } }
    end
  end

  # GET /admin/performance/memory
  def memory
    authorize [:admin, :performance], :show?
    
    @memory_usage = PerformanceMonitoringService.get_metrics[:memory_usage]
    @gc_stats = collect_gc_stats
    
    respond_to do |format|
      format.html { render :memory }
      format.json { render json: { memory_usage: @memory_usage, gc_stats: @gc_stats } }
    end
  end

  # POST /admin/performance/reset
  def reset
    authorize [:admin, :performance], :reset?
    
    PerformanceMonitoringService.reset_metrics
    
    flash[:notice] = 'Performance metrics have been reset'
    
    respond_to do |format|
      format.html { redirect_to admin_performance_index_path }
      format.json { render json: { status: 'success', message: 'Metrics reset' } }
    end
  end

  # GET /admin/performance/export
  def export
    authorize [:admin, :performance], :export?
    
    metrics = PerformanceMonitoringService.get_metrics
    request_stats = PerformanceMonitoringService.get_request_stats
    slow_queries = PerformanceMonitoringService.get_slow_queries(limit: 100)
    
    export_data = {
      exported_at: Time.current.iso8601,
      metrics: metrics,
      request_stats: request_stats,
      slow_queries: slow_queries,
      system_info: {
        ruby_version: RUBY_VERSION,
        rails_version: Rails.version,
        environment: Rails.env
      }
    }
    
    respond_to do |format|
      format.json { render json: export_data }
      format.csv { send_csv_export(export_data) }
    end
  end

  private

  def collect_gc_stats
    return {} unless defined?(GC)
    
    {
      count: GC.count,
      heap_allocated_pages: GC.stat[:heap_allocated_pages],
      heap_sorted_length: GC.stat[:heap_sorted_length],
      heap_allocatable_pages: GC.stat[:heap_allocatable_pages],
      heap_available_slots: GC.stat[:heap_available_slots],
      heap_live_slots: GC.stat[:heap_live_slots],
      heap_free_slots: GC.stat[:heap_free_slots],
      total_allocated_pages: GC.stat[:total_allocated_pages],
      total_freed_pages: GC.stat[:total_freed_pages]
    }
  end

  def send_csv_export(data)
    csv_data = generate_csv_export(data)
    send_data csv_data, 
              filename: "performance_metrics_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv'
  end

  def generate_csv_export(data)
    require 'csv'
    
    CSV.generate do |csv|
      # Headers
      csv << ['Metric', 'Value', 'Timestamp']
      
      # Summary metrics
      data[:metrics][:summary].each do |key, value|
        csv << [key.to_s.humanize, value, data[:exported_at]]
      end
      
      # Request stats
      data[:request_stats].each do |key, value|
        csv << ["Request #{key.to_s.humanize}", value, data[:exported_at]]
      end
      
      # Top slow queries
      csv << [] # Empty row
      csv << ['Slow Queries', '', '']
      csv << ['Query', 'Avg Duration (ms)', 'Count']
      
      data[:slow_queries].first(10).each do |query|
        csv << [query[:query].truncate(100), query[:avg_duration], query[:count]]
      end
    end
  end
end
