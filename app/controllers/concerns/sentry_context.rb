# Sentry Context Concern
# Adds user and application context to Sentry error reports for better debugging
module SentryContext
  extend ActiveSupport::Concern

  included do
    before_action :set_sentry_context, if: -> { sentry_context_enabled? }
  end

  private

  def sentry_context_enabled?
    return false if Rails.env.test?
    return false unless defined?(Sentry) && Sentry.respond_to?(:set_user)
    return false if ENV['SENTRY_DSN'].to_s.strip.empty?

    enabled_envs = %w[production staging]
    enabled_envs.include?(Rails.env)
  end

  def set_sentry_context
    return if request.env['sentry_context_set']
    request.env['sentry_context_set'] = true

    return unless defined?(Sentry) && Sentry.respond_to?(:set_user)

    begin
      # Set user context if user is authenticated
      if respond_to?(:current_user) && current_user
        Sentry.set_user(
          id: current_user.id,
          email: current_user.email,
          username: current_user.name || current_user.email,
        )
      end

      # Set restaurant context if available
      if instance_variable_defined?(:@restaurant) && @restaurant
        Sentry.set_tag('restaurant_id', @restaurant.id)
        Sentry.set_tag('restaurant_name', @restaurant.name)
      end

      # Set current employee context if available
      if respond_to?(:current_employee) && current_employee
        Sentry.set_tag('employee_id', current_employee.id)
        Sentry.set_tag('employee_role', current_employee.role) if current_employee.respond_to?(:role)
      end

      # Set request context
      Sentry.set_tag('controller', controller_name)
      Sentry.set_tag('action', action_name)
      Sentry.set_tag('request_method', request.method)

      # Set additional context for debugging
      Sentry.set_context('request_info', {
        url: request.url,
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
        referer: request.referer,
      })
    rescue StandardError => e
      # Silently fail in test environment or if Sentry is not properly configured
      Rails.logger.debug { "Sentry context setting failed: #{e.message}" } if Rails.env.development?
    end
  end
end
