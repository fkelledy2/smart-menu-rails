# Middleware for collecting HTTP request metrics
class MetricsMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    # Skip metrics collection for certain paths
    return @app.call(env) if skip_metrics?(request.path)

    start_time = Time.current

    # Process request
    status, headers, response = @app.call(env)

    # Calculate metrics
    duration = Time.current - start_time
    response_size = calculate_response_size(response)

    # Record metrics
    record_http_metrics(request, status, duration, response_size)

    [status, headers, response]
  rescue StandardError => e
    # Record error metrics
    duration = Time.current - start_time if start_time
    record_error_metrics(request, e, duration)
    raise
  end

  private

  def skip_metrics?(path)
    # Skip metrics for assets, health checks, etc.
    path.start_with?('/assets', '/packs') ||
      path == '/health' ||
      path == '/favicon.ico' ||
      path == '/metrics' # Avoid recursive metrics collection
  end

  def record_http_metrics(request, status, duration, response_size)
    labels = {
      method: request.method,
      status: status_category(status),
      endpoint: normalize_endpoint(request.path),
    }

    # Increment request counter
    MetricsCollector.increment(:http_requests_total, 1, **labels)

    # Record request duration
    MetricsCollector.observe(:http_request_duration, duration, **labels)

    # Record response size
    MetricsCollector.observe(:http_response_size, response_size, **labels) if response_size

    # Record slow requests separately
    if duration > 1.0 # Requests slower than 1 second
      MetricsCollector.increment(:slow_requests_total, 1, **labels)
    end
  end

  def record_error_metrics(request, error, duration)
    labels = {
      method: request.method,
      error_class: error.class.name,
      endpoint: normalize_endpoint(request.path),
    }

    MetricsCollector.increment(:errors_total, 1, **labels)

    if duration
      MetricsCollector.observe(:error_request_duration, duration, **labels)
    end
  end

  def status_category(status)
    case status
    when 200..299 then '2xx'
    when 300..399 then '3xx'
    when 400..499 then '4xx'
    when 500..599 then '5xx'
    else 'unknown'
    end
  end

  def normalize_endpoint(path)
    # Normalize paths to reduce cardinality
    # Replace IDs with placeholders
    normalized = path.gsub(%r{/\d+}, '/:id')

    # Limit path length and complexity
    parts = normalized.split('/').first(4) # Keep only first 4 path segments
    parts.join('/')
  end

  def calculate_response_size(response)
    return nil unless response.respond_to?(:each)

    size = 0
    response.each { |chunk| size += chunk.bytesize if chunk.respond_to?(:bytesize) }
    size
  rescue StandardError
    nil # Return nil if we can't calculate size
  end
end
