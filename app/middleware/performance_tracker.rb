class PerformanceTracker
  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless should_track?(env)

    start_time = Time.current
    memory_before = get_memory_usage

    status, headers, response = @app.call(env)

    duration = (Time.current - start_time) * 1000 # Convert to ms
    memory_after = get_memory_usage
    memory_delta = memory_after - memory_before

    # Track performance asynchronously to avoid impacting response time
    PerformanceTrackingJob.perform_later(
      endpoint: extract_endpoint(env),
      response_time: duration,
      memory_usage: memory_delta,
      status_code: status,
      user_id: extract_user_id(env),
      controller: extract_controller(env),
      action: extract_action(env),
      timestamp: start_time,
      additional_data: extract_additional_data(env, headers),
    )

    [status, headers, response]
  end

  private

  def should_track?(env)
    # Don't track if APM is disabled
    return false unless Rails.application.config.respond_to?(:enable_apm) && Rails.application.config.enable_apm

    # Don't track asset requests
    return false if env['PATH_INFO'].start_with?('/assets', '/packs')

    # Don't track health checks
    return false if env['PATH_INFO'] == '/up'

    # Sample based on configuration
    sample_rate = Rails.application.config.apm_sample_rate || 1.0
    return false if rand > sample_rate

    true
  end

  def extract_endpoint(env)
    "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
  end

  def extract_user_id(env)
    # Try to extract user ID from session or request
    request = ActionDispatch::Request.new(env)
    session = request.session

    # Check for user_id in session (Devise pattern)
    session['warden.user.user.key']&.first&.first ||
      # Check for user_id in params (API pattern)
      request.params['user_id'] ||
      # Check for Authorization header (JWT pattern)
      extract_user_from_auth_header(env['HTTP_AUTHORIZATION'])
  end

  def extract_controller(env)
    # Extract from Rails routing
    request = ActionDispatch::Request.new(env)
    Rails.application.routes.recognize_path(request.path, method: request.method)[:controller]
  rescue StandardError
    'unknown'
  end

  def extract_action(env)
    # Extract from Rails routing
    request = ActionDispatch::Request.new(env)
    Rails.application.routes.recognize_path(request.path, method: request.method)[:action]
  rescue StandardError
    'unknown'
  end

  def extract_additional_data(env, headers)
    {
      user_agent: env['HTTP_USER_AGENT'],
      referer: env['HTTP_REFERER'],
      remote_ip: env['REMOTE_ADDR'],
      content_type: headers['Content-Type'],
      content_length: headers['Content-Length'],
    }
  end

  def extract_user_from_auth_header(_auth_header)
    # Placeholder for JWT token extraction
    # Implementation would depend on your authentication system
    nil
  end

  def get_memory_usage
    # Get RSS memory in bytes
    if RUBY_PLATFORM.include?('linux')
      # Linux: read from /proc/self/status
      status = File.read('/proc/self/status')
      if status =~ /VmRSS:\s*(\d+)\s*kB/
        ::Regexp.last_match(1).to_i * 1024 # Convert KB to bytes
      else
        0
      end
    elsif RUBY_PLATFORM.include?('darwin')
      # macOS: use ps command
      pid = Process.pid
      rss_kb = `ps -o rss= -p #{pid}`.strip.to_i
      rss_kb * 1024 # Convert KB to bytes
    else
      # Fallback: use Ruby's memory info if available
      GC.stat[:heap_allocated_pages] * 16384 # Approximate
    end
  rescue StandardError
    0
  end
end
