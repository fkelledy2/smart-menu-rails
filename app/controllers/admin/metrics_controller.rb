# Admin controller for viewing application metrics
class Admin::MetricsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin!
  
  # Pundit authorization
  after_action :verify_authorized

  def index
    authorize [:admin, :metrics]
    
    @metrics_summary = build_metrics_summary
    @system_metrics = collect_system_metrics
    @recent_metrics = collect_recent_metrics
  end

  def show
    authorize [:admin, :metrics]
    
    @metric_name = params[:id]
    @metric_data = MetricsCollector.get_metrics.select { |k, _| k.include?(@metric_name) }
    @metric_summary = build_metric_summary(@metric_name)
  end

  def export
    authorize [:admin, :metrics]
    
    metrics = MetricsCollector.get_metrics

    respond_to do |format|
      format.json { render json: metrics }
      format.csv { send_csv_data(metrics) }
    end
  end

  private

  def authenticate_admin!
    # Add your admin authentication logic here
    # For now, just check if user is present and has admin role
    redirect_to root_path unless current_user&.admin?
  rescue NoMethodError
    # If admin? method doesn't exist, just check for user presence
    redirect_to root_path unless current_user
  end

  def build_metrics_summary
    {
      http_requests: summarize_counter_metric(:http_requests_total),
      errors: summarize_counter_metric(:errors_total),
      user_registrations: summarize_counter_metric(:user_registrations_total),
      restaurant_creations: summarize_counter_metric(:restaurant_creations_total),
      menu_imports: summarize_counter_metric(:menu_imports_total),
      avg_response_time: calculate_average_response_time,
      error_rate: calculate_error_rate,
    }
  end

  def collect_system_metrics
    MetricsCollector.collect_system_metrics

    {
      memory_usage: MetricsCollector.get_metric_summary(:memory_usage),
      active_users: MetricsCollector.get_metric_summary(:active_users),
      db_pool_size: MetricsCollector.get_metric_summary(:db_pool_size),
      db_pool_checked_out: MetricsCollector.get_metric_summary(:db_pool_checked_out),
    }.compact
  end

  def collect_recent_metrics
    # Get metrics from the last hour
    all_metrics = MetricsCollector.get_metrics
    recent_cutoff = 1.hour.ago

    all_metrics.select do |_, metric_data|
      metric_data[:last_updated] && metric_data[:last_updated] > recent_cutoff
    end
  end

  def summarize_counter_metric(metric_name)
    all_metrics = MetricsCollector.get_metrics
    counter_metrics = all_metrics.select { |k, v| k.include?(metric_name.to_s) && v[:type] == :counter }

    {
      total: counter_metrics.sum { |_, v| v[:value] },
      count: counter_metrics.size,
      breakdown: counter_metrics.transform_values { |v| v[:value] },
    }
  end

  def calculate_average_response_time
    summary = MetricsCollector.get_metric_summary(:http_request_duration)
    summary&.dig(:avg) || 0
  end

  def calculate_error_rate
    total_requests = summarize_counter_metric(:http_requests_total)[:total]
    total_errors = summarize_counter_metric(:errors_total)[:total]

    return 0 if total_requests.zero?

    (total_errors.to_f / total_requests * 100).round(2)
  end

  def build_metric_summary(metric_name)
    MetricsCollector.get_metric_summary(metric_name.to_sym)
  end

  def send_csv_data(metrics)
    csv_data = generate_csv(metrics)
    send_data csv_data,
              filename: "metrics_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv'
  end

  def generate_csv(metrics)
    require 'csv'

    CSV.generate do |csv|
      csv << ['Metric Name', 'Type', 'Value', 'Labels', 'Last Updated']

      metrics.each do |key, data|
        csv << [
          key,
          data[:type],
          format_metric_value(data),
          data[:labels]&.to_json || '{}',
          data[:last_updated]&.iso8601,
        ]
      end
    end
  end

  def format_metric_value(data)
    case data[:type]
    when :counter, :gauge
      data[:value]
    when :histogram
      "count: #{data[:values]&.size || 0}, avg: #{calculate_histogram_avg(data[:values])}"
    else
      data.to_json
    end
  end

  def calculate_histogram_avg(values)
    return 0 if values.blank?

    numeric_values = values.pluck(:value).compact
    return 0 if numeric_values.empty?

    (numeric_values.sum / numeric_values.size.to_f).round(4)
  end
end
