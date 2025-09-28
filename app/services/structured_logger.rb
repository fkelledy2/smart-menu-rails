# Structured logging service for consistent logging across the application
# Provides JSON-formatted logs with contextual information for better observability
class StructuredLogger
  include Singleton

  # Log levels
  LEVELS = %w[debug info warn error fatal].freeze

  # Standard log fields
  STANDARD_FIELDS = %w[timestamp level message service].freeze

  class << self
    # Delegate logging methods to the singleton instance
    LEVELS.each do |level|
      define_method(level) do |message = nil, **context, &block|
        instance.public_send(level, message, **context, &block)
      end
    end

    # Log with custom level
    def log(level, message = nil, **context, &)
      instance.log(level, message, **context, &)
    end

    # Create a logger for a specific service/class
    def for_service(service_name)
      ServiceLogger.new(service_name)
    end
  end

  def initialize
    @service_name = 'rails_app'
  end

  # Use Rails.logger dynamically to support test logger swapping
  def logger
    Rails.logger
  end

  # Log methods for each level
  LEVELS.each do |level|
    define_method(level) do |message = nil, **context, &block|
      log(level.to_sym, message, **context, &block)
    end
  end

  # Main logging method
  def log(level, message = nil, **context, &)
    return unless should_log?(level)

    # Build the log entry
    log_entry = build_log_entry(level, message, context, &)

    # Output the structured log
    logger.public_send(level, format_log_entry(log_entry))
  end

  private

  def should_log?(level)
    logger.public_send("#{level}?")
  end

  def build_log_entry(level, message, context)
    entry = {
      timestamp: Time.current.iso8601(3),
      level: level.to_s.upcase,
      service: @service_name,
      pid: Process.pid,
      thread_id: Thread.current.object_id,
    }

    # Add message
    if block_given?
      entry[:message] = yield
    elsif message
      entry[:message] = message.to_s
    end

    # Add request context if available
    entry.merge!(request_context)

    # Add user context if available
    entry.merge!(user_context)

    # Add custom context
    entry.merge!(context) if context.any?

    entry
  end

  def format_log_entry(entry)
    if Rails.env.development?
      # Human-readable format for development
      format_development_log(entry)
    else
      # JSON format for production
      entry.to_json
    end
  end

  def format_development_log(entry)
    timestamp = entry[:timestamp]
    level = entry[:level].ljust(5)
    service = entry[:service]
    message = entry[:message]

    base = "[#{timestamp}] #{level} #{service}: #{message}"

    # Add context if present
    context_fields = entry.except(:timestamp, :level, :service, :message, :pid, :thread_id)
    if context_fields.any?
      context_str = context_fields.map { |k, v| "#{k}=#{v}" }.join(' ')
      base += " | #{context_str}"
    end

    base
  end

  def request_context
    return {} unless defined?(Current) && Current.respond_to?(:request_id)

    context = {}
    context[:request_id] = Current.request_id if Current.request_id
    context[:user_agent] = Current.user_agent if Current.respond_to?(:user_agent) && Current.user_agent
    context[:ip_address] = Current.ip_address if Current.respond_to?(:ip_address) && Current.ip_address
    context
  end

  def user_context
    return {} unless defined?(Current) && Current.respond_to?(:user)

    context = {}
    if Current.user
      context[:user_id] = Current.user.id
      context[:user_email] = Current.user.email if Current.user.respond_to?(:email)
    end
    context
  end

  # Service-specific logger
  class ServiceLogger
    def initialize(service_name)
      @service_name = service_name
    end

    LEVELS.each do |level|
      define_method(level) do |message = nil, **context, &block|
        log(level.to_sym, message, **context, &block)
      end
    end

    def log(level, message = nil, **context, &)
      context[:service] = @service_name
      StructuredLogger.instance.log(level, message, **context, &)
    end
  end
end
