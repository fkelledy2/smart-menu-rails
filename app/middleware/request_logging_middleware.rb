# Middleware for enhanced request logging and timing
class RequestLoggingMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)

    # Skip logging for certain paths
    return @app.call(env) if skip_logging?(request.path)

    # Generate request ID if not present
    request_id = env['action_dispatch.request_id'] ||= SecureRandom.uuid

    # Set up request context
    start_time = Time.current

    # Log request start
    log_request_start(request, request_id)

    # Process request
    status, headers, response = @app.call(env)

    # Calculate duration
    duration = ((Time.current - start_time) * 1000).round(2)

    # Log request completion
    log_request_end(request, request_id, status, duration)

    [status, headers, response]
  rescue StandardError => e
    # Log error
    duration = ((Time.current - start_time) * 1000).round(2) if start_time
    log_request_error(request, request_id, e, duration)
    raise
  end

  private

  def skip_logging?(path)
    # Skip logging for assets, health checks, etc.
    path.start_with?('/assets', '/packs') ||
      path == '/health' ||
      path == '/favicon.ico'
  end

  def log_request_start(request, request_id)
    StructuredLogger.info(
      'HTTP request started',
      request_id: request_id,
      method: request.method,
      path: request.path,
      remote_ip: request.remote_ip,
      user_agent: request.user_agent,
      referer: request.referer,
      format: request.format&.symbol,
    )
  end

  def log_request_end(request, request_id, status, duration)
    StructuredLogger.info(
      'HTTP request completed',
      request_id: request_id,
      method: request.method,
      path: request.path,
      status: status,
      duration_ms: duration,
      format: request.format&.symbol,
    )
  end

  def log_request_error(request, request_id, error, duration)
    StructuredLogger.error(
      'HTTP request failed',
      request_id: request_id,
      method: request.method,
      path: request.path,
      error_class: error.class.name,
      error_message: error.message,
      duration_ms: duration,
      backtrace: error.backtrace&.first(5),
    )
  end
end
