# Concern for tracking business metrics in controllers
module MetricsTracking
  extend ActiveSupport::Concern

  included do
    # Track controller action execution
    around_action :track_action_metrics
  end

  private

  def track_action_metrics
    action_start = Time.current

    yield

    duration = Time.current - action_start

    # Track action execution time
    MetricsCollector.observe(
      :controller_action_duration,
      duration,
      controller: controller_name,
      action: action_name,
      user_type: user_type_for_metrics,
    )

    # Track successful actions
    MetricsCollector.increment(
      :controller_actions_total,
      1,
      controller: controller_name,
      action: action_name,
      status: 'success',
    )
  rescue StandardError => e
    # Track failed actions
    MetricsCollector.increment(
      :controller_actions_total,
      1,
      controller: controller_name,
      action: action_name,
      status: 'error',
      error_class: e.class.name,
    )
    raise
  end

  # Helper methods for tracking specific business events
  def track_user_registration(user)
    MetricsCollector.increment(:user_registrations_total, 1, plan: user.plan&.key || 'unknown')
  end

  def track_restaurant_creation(restaurant)
    MetricsCollector.increment(
      :restaurant_creations_total,
      1,
      user_plan: restaurant.user.plan&.key || 'unknown',
    )
  end

  def track_menu_import(import)
    MetricsCollector.increment(
      :menu_imports_total,
      1,
      status: import.status,
      import_type: 'ocr',
    )
  end

  def track_order_creation(order)
    MetricsCollector.increment(:orders_total, 1, restaurant_id: order.restaurant_id)
    MetricsCollector.observe(:order_value, order.total_amount, currency: order.currency)
  end

  def track_payment_processing(payment)
    MetricsCollector.increment(
      :payments_total,
      1,
      status: payment.status,
      provider: payment.provider || 'unknown',
    )

    if payment.successful?
      MetricsCollector.observe(:payment_amount, payment.amount, currency: payment.currency)
    end
  end

  def track_external_api_call(api_name, duration, success = true)
    status = success ? 'success' : 'error'

    MetricsCollector.increment(:external_api_calls_total, 1, api: api_name, status: status)
    MetricsCollector.observe(:external_api_duration, duration, api: api_name, status: status)

    unless success
      MetricsCollector.increment(:external_api_errors_total, 1, api: api_name)
    end
  end

  def track_database_query(query_type, duration, table_name = nil)
    labels = { query_type: query_type }
    labels[:table] = table_name if table_name

    MetricsCollector.increment(:db_queries_total, 1, **labels)
    MetricsCollector.observe(:db_query_duration, duration, **labels)
  end

  def track_user_activity(activity_type, user = nil)
    user ||= current_user
    labels = { activity: activity_type }
    labels[:user_plan] = user.plan&.key if user&.plan

    MetricsCollector.increment(:user_activities_total, 1, **labels)
  end

  def track_feature_usage(feature_name, user = nil)
    user ||= current_user
    labels = { feature: feature_name }
    labels[:user_plan] = user.plan&.key if user&.plan

    MetricsCollector.increment(:feature_usage_total, 1, **labels)
  end

  def track_error_occurrence(error, context = {})
    MetricsCollector.increment(
      :application_errors_total,
      1,
      error_class: error.class.name,
      controller: controller_name,
      action: action_name,
      **context,
    )
  end

  # Performance tracking helpers
  def track_slow_operation(operation_name, threshold = 1.0)
    start_time = Time.current
    result = yield
    duration = Time.current - start_time

    if duration > threshold
      MetricsCollector.increment(
        :slow_operations_total,
        1,
        operation: operation_name,
        controller: controller_name,
        action: action_name,
      )
    end

    MetricsCollector.observe(
      :operation_duration,
      duration,
      operation: operation_name,
    )

    result
  end

  def user_type_for_metrics
    return 'anonymous' unless respond_to?(:current_user) && current_user
    return 'admin' if current_user.respond_to?(:admin?) && current_user.admin?
    return 'premium' if current_user.plan&.key != 'free'

    'free'
  end
end
