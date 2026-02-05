# frozen_string_literal: true

class AuthorizationMonitoringService
  include Singleton

  def self.track_authorization_check(user, resource, action, result, context = {})
    instance.track_authorization_check(user, resource, action, result, context)
  end

  def self.track_authorization_failure(user, resource, action, exception, context = {})
    instance.track_authorization_failure(user, resource, action, exception, context)
  end

  def self.generate_authorization_report(start_date = 1.week.ago, end_date = Time.current)
    instance.generate_authorization_report(start_date, end_date)
  end

  def track_authorization_check(user, resource, action, result, context = {})
    log_data = {
      event: 'authorization_check',
      user_id: user&.id,
      user_role: determine_user_role(user, resource),
      resource_type: resource&.class&.name,
      resource_id: resource.respond_to?(:id) ? resource&.id : nil,
      action: action.to_s,
      result: result,
      timestamp: Time.current,
      controller: context[:controller],
      request_ip: context[:request_ip],
      user_agent: context[:user_agent],
    }

    Rails.logger.info "Authorization Check: #{log_data}"

    # Store in Redis for real-time monitoring (optional)
    store_in_redis(log_data) if Rails.env.production?

    # Track metrics
    track_authorization_metrics(log_data)
  end

  def track_authorization_failure(user, resource, action, exception, context = {})
    log_data = {
      event: 'authorization_failure',
      user_id: user&.id,
      user_role: determine_user_role(user, resource),
      resource_type: resource&.class&.name,
      resource_id: resource.respond_to?(:id) ? resource&.id : nil,
      action: action.to_s,
      error: exception.class.name,
      error_message: exception.message,
      timestamp: Time.current,
      controller: context[:controller],
      request_ip: context[:request_ip],
      user_agent: context[:user_agent],
      backtrace: exception.backtrace&.first(5),
    }

    Rails.logger.warn "Authorization Failure: #{log_data}"

    # Store in Redis for alerting
    store_failure_in_redis(log_data) if Rails.env.production?

    # Track failure metrics
    track_authorization_failure_metrics(log_data)

    # Send alerts for suspicious patterns
    check_for_suspicious_activity(log_data)
  end

  def generate_authorization_report(start_date, end_date)
    {
      period: "#{start_date.strftime('%Y-%m-%d')} to #{end_date.strftime('%Y-%m-%d')}",
      summary: generate_summary_stats(start_date, end_date),
      by_user_role: generate_role_breakdown(start_date, end_date),
      by_resource_type: generate_resource_breakdown(start_date, end_date),
      by_action: generate_action_breakdown(start_date, end_date),
      failures: generate_failure_analysis(start_date, end_date),
      recommendations: generate_recommendations(start_date, end_date),
    }
  end

  private

  def determine_user_role(user, resource)
    return 'anonymous' unless user

    # Check if user owns the resource's restaurant
    restaurant = extract_restaurant(resource)
    return 'owner' if restaurant&.user_id == user.id

    # Check employee role
    if restaurant && user.employees.exists?(restaurant: restaurant, status: :active)
      employee = user.employees.find_by(restaurant: restaurant, status: :active)
      return "employee_#{employee.role}"
    end

    # Check if user is a participant in orders
    if resource.is_a?(Ordr) && resource.ordrparticipants.exists?(user: user)
      return 'order_participant'
    end

    'customer'
  end

  def extract_restaurant(resource)
    return resource if resource.is_a?(Restaurant)
    return resource.restaurant if resource.respond_to?(:restaurant)
    return resource.menu.restaurant if resource.respond_to?(:menu) && resource.menu

    nil
  end

  def store_in_redis(log_data)
    return unless defined?(Redis)

    # Try to get the underlying Redis client
    redis = Rails.cache.redis rescue nil
    return unless redis

    key = "authorization_checks:#{Date.current.strftime('%Y-%m-%d')}"
    begin
      redis.lpush(key, log_data.to_json)
      redis.expire(key, 7.days.to_i)
    rescue StandardError => e
      # Fallback to Rails.cache with proper expiry
      Rails.logger.debug "[AuthorizationMonitoring] Using fallback cache storage: #{e.message}"
      begin
        Rails.cache.write(key, log_data, expires_in: 7.days)
      rescue StandardError => e2
        Rails.logger.error "Failed to store authorization data: #{e2.message}"
      end
    end
  end

  def store_failure_in_redis(log_data)
    return unless defined?(Redis)

    # Try to get the underlying Redis client
    redis = Rails.cache.redis rescue nil
    return unless redis

    key = "authorization_failures:#{Date.current.strftime('%Y-%m-%d')}"
    recent_key = 'recent_authorization_failures'

    begin
      redis.lpush(key, log_data.to_json)
      redis.expire(key, 30.days.to_i)

      # Store recent failures for alerting
      redis.lpush(recent_key, log_data.to_json)
      redis.ltrim(recent_key, 0, 99) # Keep last 100 failures
      redis.expire(recent_key, 1.hour.to_i)
    rescue StandardError => e
      # Fallback to Rails.cache with proper expiry
      Rails.logger.debug "[AuthorizationMonitoring] Using fallback cache storage: #{e.message}"
      begin
        Rails.cache.write(key, log_data, expires_in: 30.days)
        Rails.cache.write(recent_key, log_data, expires_in: 1.hour)
      rescue StandardError => e2
        Rails.logger.error "Failed to store authorization failure: #{e2.message}"
      end
    end
  end

  def track_authorization_metrics(log_data)
    # Increment counters for monitoring
    Rails.logger.info "Authorization Metrics: #{
      {
        metric: 'authorization_check_count',
        user_role: log_data[:user_role],
        resource_type: log_data[:resource_type],
        action: log_data[:action],
        result: log_data[:result],
      }
    }"
  end

  def track_authorization_failure_metrics(log_data)
    Rails.logger.warn "Authorization Failure Metrics: #{
      {
        metric: 'authorization_failure_count',
        user_role: log_data[:user_role],
        resource_type: log_data[:resource_type],
        action: log_data[:action],
        error: log_data[:error],
      }
    }"
  end

  def check_for_suspicious_activity(log_data)
    return unless Rails.env.production?

    user_id = log_data[:user_id]
    return unless user_id

    # Check for rapid repeated failures from same user
    recent_failures = get_recent_failures_for_user(user_id)

    return unless recent_failures.count >= 10 # 10 failures in last hour

    send_security_alert('Suspicious authorization activity detected', {
      user_id: user_id,
      failure_count: recent_failures.count,
      recent_failures: recent_failures.last(5),
    },)
  end

  def get_recent_failures_for_user(user_id)
    return [] unless defined?(Redis)

    # Try to get the underlying Redis client
    redis = Rails.cache.redis rescue nil
    return [] unless redis

    key = 'recent_authorization_failures'
    begin
      failures = redis.lrange(key, 0, -1)

      failures.filter_map do |f|
        JSON.parse(f)
      rescue StandardError
        nil
      end
        .select { |f| f['user_id'] == user_id }
        .select { |f| Time.zone.parse(f['timestamp']) > 1.hour.ago }
    rescue StandardError => e
      Rails.logger.error "Failed to get recent failures: #{e.message}"
      []
    end
  end

  def send_security_alert(message, data)
    Rails.logger.error "SECURITY ALERT: #{message} - #{data}"

    # In production, you might want to:
    # - Send to Slack/Discord
    # - Email administrators
    # - Create incident tickets
    # - Trigger monitoring alerts
  end

  def generate_summary_stats(_start_date, _end_date)
    {
      total_checks: 0, # Would query logs/metrics
      total_failures: 0,
      failure_rate: 0.0,
      unique_users: 0,
      most_common_failure: 'Pundit::NotAuthorizedError',
    }
  end

  def generate_role_breakdown(_start_date, _end_date)
    {
      'owner' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'employee_admin' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'employee_manager' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'employee_staff' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'customer' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'anonymous' => { checks: 0, failures: 0, failure_rate: 0.0 },
    }
  end

  def generate_resource_breakdown(_start_date, _end_date)
    {
      'Restaurant' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'Menu' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'Ordr' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'Employee' => { checks: 0, failures: 0, failure_rate: 0.0 },
    }
  end

  def generate_action_breakdown(_start_date, _end_date)
    {
      'show' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'update' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'destroy' => { checks: 0, failures: 0, failure_rate: 0.0 },
      'analytics' => { checks: 0, failures: 0, failure_rate: 0.0 },
    }
  end

  def generate_failure_analysis(_start_date, _end_date)
    {
      most_common_errors: [],
      most_targeted_resources: [],
      most_active_users: [],
      suspicious_patterns: [],
    }
  end

  def generate_recommendations(_start_date, _end_date)
    [
      'Review employee role permissions for high-failure actions',
      'Consider additional training for users with high failure rates',
      'Audit resource access patterns for potential security improvements',
      'Implement additional logging for suspicious authorization patterns',
    ]
  end
end
