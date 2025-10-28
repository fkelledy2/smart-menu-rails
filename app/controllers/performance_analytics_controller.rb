class PerformanceAnalyticsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!

  def dashboard
    @current_metrics = PerformanceMetricsService.current_snapshot
    @performance_trends = PerformanceMetricsService.trends(24.hours)
    @slow_endpoints = PerformanceMetricsService.slow_endpoints(1.hour)
    @slow_queries = SlowQuery.slowest_queries(5, 1.hour)
    @memory_status = MemoryMonitoringService.current_memory_snapshot
  end

  def api_metrics
    timeframe = parse_timeframe(params[:timeframe] || '1h')

    render json: {
      current_snapshot: PerformanceMetricsService.current_snapshot,
      trends: PerformanceMetricsService.trends(timeframe),
      slow_endpoints: PerformanceMetricsService.slow_endpoints(timeframe),
      memory_status: MemoryMonitoringService.current_memory_snapshot,
    }
  end

  def endpoint_analysis
    endpoint = params[:endpoint]
    timeframe = parse_timeframe(params[:timeframe] || '24h')

    if endpoint.blank?
      render json: { error: 'Endpoint parameter is required' }, status: :bad_request
      return
    end

    analysis = PerformanceMetricsService.endpoint_analysis(endpoint, timeframe)

    if analysis
      render json: analysis
    else
      render json: { error: 'No data found for endpoint' }, status: :not_found
    end
  end

  def slow_queries
    timeframe = parse_timeframe(params[:timeframe] || '1h')
    limit = [params[:limit].to_i, 50].min.positive? ? params[:limit].to_i : 10

    queries = SlowQuery.slowest_queries(limit, timeframe)

    render json: {
      queries: queries.map do |query|
        {
          id: query.id,
          sql: query.sql.truncate(200),
          duration: query.duration,
          formatted_duration: query.formatted_duration,
          table_name: query.table_name,
          timestamp: query.timestamp,
          potential_n_plus_one: query.potential_n_plus_one?,
        }
      end,
      summary: {
        total_count: queries.count,
        avg_duration: queries.average(&:duration)&.round(2),
        timeframe: timeframe_description(timeframe),
      },
    }
  end

  def memory_analysis
    timeframe = parse_timeframe(params[:timeframe] || '1h')

    render json: {
      current: MemoryMonitoringService.current_memory_snapshot,
      trend: MemoryMetric.memory_trend(timeframe),
      leak_detected: MemoryMetric.detect_memory_leak,
      recent_metrics: MemoryMetric.recent(timeframe).limit(100).map do |metric|
        {
          timestamp: metric.timestamp,
          rss_memory: metric.rss_memory,
          formatted_rss: metric.formatted_rss_memory,
          heap_size: metric.heap_size,
          gc_count: metric.gc_count,
        }
      end,
    }
  end

  def performance_summary
    timeframe = parse_timeframe(params[:timeframe] || '24h')

    render json: PerformanceMetricsService.performance_summary(timeframe)
  end

  def export_metrics
    timeframe = parse_timeframe(params[:timeframe] || '24h')
    format = params[:format] || 'json'

    case format.downcase
    when 'csv'
      export_csv(timeframe)
    when 'json'
      export_json(timeframe)
    else
      render json: { error: 'Unsupported format. Use csv or json.' }, status: :bad_request
    end
  end

  private

  def ensure_admin!
    return if current_user&.admin?

    respond_to do |format|
      format.html do
        flash[:alert] = 'Access denied. Admin privileges required.'
        redirect_to root_path
      end
      format.json { render json: { error: 'Admin access required' }, status: :forbidden }
    end
  end

  def parse_timeframe(timeframe_str)
    case timeframe_str.downcase
    when '5m', '5min'
      5.minutes
    when '15m', '15min'
      15.minutes
    when '1h', '1hour'
      1.hour
    when '6h', '6hours'
      6.hours
    when '24h', '1d', '1day'
      24.hours
    when '7d', '1w', '1week'
      7.days
    when '30d', '1m', '1month'
      30.days
    else
      1.hour # default
    end
  end

  def timeframe_description(timeframe)
    case timeframe
    when 5.minutes
      'Last 5 minutes'
    when 15.minutes
      'Last 15 minutes'
    when 1.hour
      'Last hour'
    when 6.hours
      'Last 6 hours'
    when 24.hours
      'Last 24 hours'
    when 7.days
      'Last 7 days'
    when 30.days
      'Last 30 days'
    else
      "Last #{timeframe.inspect}"
    end
  end

  def export_csv(timeframe)
    require 'csv'

    metrics = PerformanceMetric.recent(timeframe).includes(:user)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << ['Timestamp', 'Endpoint', 'Response Time (ms)', 'Status Code', 'Memory Usage', 'User ID', 'Controller',
              'Action',]

      metrics.find_each do |metric|
        csv << [
          metric.timestamp,
          metric.endpoint,
          metric.response_time,
          metric.status_code,
          metric.memory_usage,
          metric.user_id,
          metric.controller,
          metric.action,
        ]
      end
    end

    send_data csv_data,
              filename: "performance_metrics_#{timeframe_str}_#{Date.current}.csv",
              type: 'text/csv'
  end

  def export_json(timeframe)
    summary = PerformanceMetricsService.performance_summary(timeframe)

    send_data summary.to_json,
              filename: "performance_summary_#{timeframe_str}_#{Date.current}.json",
              type: 'application/json'
  end

  def timeframe_str
    case parse_timeframe(params[:timeframe] || '24h')
    when 5.minutes then '5min'
    when 15.minutes then '15min'
    when 1.hour then '1hour'
    when 6.hours then '6hours'
    when 24.hours then '24hours'
    when 7.days then '7days'
    when 30.days then '30days'
    else 'custom'
    end
  end
end
