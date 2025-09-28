# Application metrics collection service
# Provides a centralized way to collect and track application performance metrics
class MetricsCollector
  include Singleton

  # Metric types
  COUNTER = :counter
  GAUGE = :gauge
  HISTOGRAM = :histogram
  TIMER = :timer

  # Standard metric names
  METRICS = {
    # HTTP metrics
    http_requests_total: { type: COUNTER, description: 'Total HTTP requests' },
    http_request_duration: { type: HISTOGRAM, description: 'HTTP request duration in seconds' },
    http_response_size: { type: HISTOGRAM, description: 'HTTP response size in bytes' },

    # Database metrics
    db_queries_total: { type: COUNTER, description: 'Total database queries' },
    db_query_duration: { type: HISTOGRAM, description: 'Database query duration in seconds' },

    # Business metrics
    user_registrations_total: { type: COUNTER, description: 'Total user registrations' },
    restaurant_creations_total: { type: COUNTER, description: 'Total restaurant creations' },
    menu_imports_total: { type: COUNTER, description: 'Total menu imports' },
    orders_total: { type: COUNTER, description: 'Total orders placed' },

    # Performance metrics
    active_users: { type: GAUGE, description: 'Currently active users' },
    memory_usage: { type: GAUGE, description: 'Memory usage in bytes' },
    cpu_usage: { type: GAUGE, description: 'CPU usage percentage' },

    # Error metrics
    errors_total: { type: COUNTER, description: 'Total application errors' },
    external_api_errors_total: { type: COUNTER, description: 'Total external API errors' },
  }.freeze

  class << self
    # Delegate methods to singleton instance
    def increment(metric_name, value = 1, **labels)
      instance.increment(metric_name, value, **labels)
    end

    def decrement(metric_name, value = 1, **labels)
      instance.decrement(metric_name, value, **labels)
    end

    def set(metric_name, value, **labels)
      instance.set(metric_name, value, **labels)
    end

    def observe(metric_name, value, **labels)
      instance.observe(metric_name, value, **labels)
    end

    def time(metric_name, **labels, &)
      instance.time(metric_name, **labels, &)
    end

    delegate :collect_system_metrics, to: :instance

    delegate :get_metrics, to: :instance

    delegate :reset_metrics, to: :instance

    delegate :get_metric_summary, to: :instance
  end

  def initialize
    @metrics = {}
    @mutex = Mutex.new
    setup_periodic_collection
  end

  # Increment a counter metric
  def increment(metric_name, value = 1, **labels)
    return unless valid_metric?(metric_name, COUNTER)

    @mutex.synchronize do
      key = metric_key(metric_name, labels)
      @metrics[key] ||= { type: COUNTER, value: 0, labels: labels, last_updated: Time.current }
      @metrics[key][:value] += value
      @metrics[key][:last_updated] = Time.current
    end

    log_metric(metric_name, value, labels, :increment)
  end

  # Decrement a counter metric
  def decrement(metric_name, value = 1, **labels)
    increment(metric_name, -value, **labels)
  end

  # Set a gauge metric
  def set(metric_name, value, **labels)
    return unless valid_metric?(metric_name, GAUGE)

    @mutex.synchronize do
      key = metric_key(metric_name, labels)
      @metrics[key] = { type: GAUGE, value: value, labels: labels, last_updated: Time.current }
    end

    log_metric(metric_name, value, labels, :set)
  end

  # Observe a histogram metric
  def observe(metric_name, value, **labels)
    return unless valid_metric?(metric_name, HISTOGRAM)

    @mutex.synchronize do
      key = metric_key(metric_name, labels)
      @metrics[key] ||= { type: HISTOGRAM, values: [], labels: labels, last_updated: Time.current }
      @metrics[key][:values] << { value: value, timestamp: Time.current }

      # Keep only last 1000 values to prevent memory bloat
      @metrics[key][:values] = @metrics[key][:values].last(1000)
      @metrics[key][:last_updated] = Time.current
    end

    log_metric(metric_name, value, labels, :observe)
  end

  # Time a block and record the duration
  def time(metric_name, **labels)
    start_time = Time.current
    result = yield
    duration = Time.current - start_time

    observe(metric_name, duration, **labels)
    result
  end

  # Collect system-level metrics
  def collect_system_metrics
    # Memory usage
    if defined?(GC)
      set(:memory_usage, GC.stat[:heap_allocated_pages] * 4096) # Approximate memory usage
    end

    # Active users (from Current attributes if available)
    if defined?(Current)
      # This would need to be implemented based on your session tracking
      # set(:active_users, active_user_count)
    end

    # Database connection pool stats
    return unless defined?(ActiveRecord)

    pool = ActiveRecord::Base.connection_pool
    set(:db_pool_size, pool.size)
    # Use stat method to get checked out connections count
    set(:db_pool_checked_out, pool.stat[:busy])
  end

  # Get all collected metrics
  def get_metrics
    @mutex.synchronize do
      @metrics.dup
    end
  end

  # Reset all metrics (useful for testing)
  def reset_metrics
    @mutex.synchronize do
      @metrics.clear
    end
  end

  # Get metric summary for a specific metric
  def get_metric_summary(metric_name, **labels)
    key = metric_key(metric_name, labels)
    metric = @metrics[key]
    return nil unless metric

    case metric[:type]
    when COUNTER, GAUGE
      { value: metric[:value], last_updated: metric[:last_updated] }
    when HISTOGRAM
      values = metric[:values].pluck(:value)
      {
        count: values.size,
        sum: values.sum,
        avg: values.empty? ? 0 : values.sum / values.size.to_f,
        min: values.min,
        max: values.max,
        last_updated: metric[:last_updated],
      }
    end
  end

  private

  def valid_metric?(metric_name, expected_type = nil)
    metric_config = METRICS[metric_name.to_sym]
    return false unless metric_config
    return true unless expected_type

    metric_config[:type] == expected_type
  end

  def metric_key(metric_name, labels)
    if labels.empty?
      metric_name.to_s
    else
      "#{metric_name}#{labels.sort.to_h}"
    end
  end

  def log_metric(metric_name, value, labels, operation)
    return unless Rails.env.development?

    StructuredLogger.debug(
      'Metric recorded',
      metric: metric_name,
      operation: operation,
      value: value,
      labels: labels,
    )
  end

  def setup_periodic_collection
    # Set up a background thread to collect system metrics periodically
    return unless Rails.env.production?

    Thread.new do
      loop do
        begin
          collect_system_metrics
        rescue StandardError => e
          StructuredLogger.error('Failed to collect system metrics', error: e.message)
        end

        sleep(30) # Collect every 30 seconds
      end
    end
  end
end
