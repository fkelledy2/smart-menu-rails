# Concern for adding structured logging capabilities to controllers
module StructuredLogging
  extend ActiveSupport::Concern

  included do
    before_action :set_current_context
    after_action :log_request_completion
    around_action :log_request_timing
  end

  private

  def set_current_context
    Current.set_request_context(request)
    Current.set_user(current_user) if respond_to?(:current_user) && current_user
  end

  def log_request_completion
    StructuredLogger.info(
      'Request completed',
      controller: controller_name,
      action: action_name,
      status: response.status,
      format: request.format.symbol,
      method: request.method,
      path: request.path,
      params: filtered_params,
    )
  end

  def log_request_timing
    start_time = Time.current

    StructuredLogger.info(
      'Request started',
      controller: controller_name,
      action: action_name,
      method: request.method,
      path: request.path,
      format: request.format.symbol,
      params: filtered_params,
    )

    yield

    duration = ((Time.current - start_time) * 1000).round(2)

    StructuredLogger.info(
      'Request timing',
      controller: controller_name,
      action: action_name,
      duration_ms: duration,
      status: response.status,
    )
  end

  def filtered_params
    # Filter sensitive parameters
    filter = ActionDispatch::Http::ParameterFilter.new(Rails.application.config.filter_parameters)
    filter.filter(params.to_unsafe_h).except('controller', 'action')
  end

  # Helper methods for controllers to use
  def log_info(message, **context)
    StructuredLogger.info(
      message,
      controller: controller_name,
      action: action_name,
      **context,
    )
  end

  def log_warn(message, **context)
    StructuredLogger.warn(
      message,
      controller: controller_name,
      action: action_name,
      **context,
    )
  end

  def log_error(message, **context)
    StructuredLogger.error(
      message,
      controller: controller_name,
      action: action_name,
      **context,
    )
  end

  def log_debug(message, **context)
    StructuredLogger.debug(
      message,
      controller: controller_name,
      action: action_name,
      **context,
    )
  end
end
