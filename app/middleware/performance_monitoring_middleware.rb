# frozen_string_literal: true

class PerformanceMonitoringMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    start_time = Time.current

    # Track memory before request
    PerformanceMonitoringService.track_memory_usage

    # Process request
    status, headers, response = @app.call(env)

    # Calculate duration
    duration = (Time.current - start_time) * 1000 # Convert to milliseconds

    # Extract request info
    request = ActionDispatch::Request.new(env)
    controller_action = extract_controller_action(env)

    # Track request performance
    PerformanceMonitoringService.track_request(
      controller: controller_action[:controller],
      action: controller_action[:action],
      duration: duration,
      status: status,
      method: request.method,
      path: request.path,
    )

    # Track memory after request
    PerformanceMonitoringService.track_memory_usage

    [status, headers, response]
  rescue StandardError => e
    # Track failed requests
    duration = (Time.current - start_time) * 1000
    controller_action = extract_controller_action(env)

    PerformanceMonitoringService.track_request(
      controller: controller_action[:controller],
      action: controller_action[:action],
      duration: duration,
      status: 500,
      method: ActionDispatch::Request.new(env).method,
      path: ActionDispatch::Request.new(env).path,
    )

    raise e
  end

  private

  def extract_controller_action(env)
    # Try to get controller/action from Rails routing
    if env['action_controller.instance']
      controller = env['action_controller.instance'].class.name
      action = env['action_controller.instance'].action_name
    elsif env['action_dispatch.request.path_parameters']
      params = env['action_dispatch.request.path_parameters']
      controller = "#{params[:controller]&.camelize}Controller"
      action = params[:action]
    else
      # Fallback for non-Rails requests
      path = env['PATH_INFO'] || '/'
      controller = 'Unknown'
      action = path.split('/').compact_blank.first || 'index'
    end

    {
      controller: controller || 'Unknown',
      action: action || 'unknown',
    }
  end
end
