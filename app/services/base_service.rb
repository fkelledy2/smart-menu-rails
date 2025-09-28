# Base class for application services providing consistent interface and error handling
class BaseService
  # Service-specific exceptions
  class Error < StandardError; end
  class ValidationError < Error; end
  class ProcessingError < Error; end

  # Result object for service operations
  class Result
    attr_reader :data, :errors, :metadata

    def initialize(success:, data: nil, errors: [], metadata: {})
      @success = success
      @data = data
      @errors = Array(errors)
      @metadata = metadata
    end

    def success?
      @success
    end

    def failure?
      !success?
    end

    def error_messages
      errors.map(&:to_s)
    end

    def first_error
      errors.first&.to_s
    end
  end

  # Class-level interface for services
  class << self
    # Call the service with given parameters
    # @param params [Hash] Parameters for the service
    # @return [Result] Service result object
    def call(**params)
      new(**params).call
    end

    # Call the service and raise on failure
    # @param params [Hash] Parameters for the service
    # @return [Object] Service result data
    # @raise [Error] If service fails
    def call!(**params)
      result = call(**params)
      raise ProcessingError, result.first_error if result.failure?

      result.data
    end
  end

  # Initialize service with parameters
  def initialize(**params)
    @params = params
    validate_params!
  end

  # Execute the service
  # @return [Result] Service result
  def call
    logger.info 'Service starting', service: self.class.name, params: sanitized_params

    begin
      data = perform
      logger.info 'Service completed successfully', service: self.class.name
      success(data)
    rescue ValidationError => e
      logger.warn 'Service validation failed', service: self.class.name, error: e.message
      failure(e.message)
    rescue ProcessingError => e
      logger.error 'Service processing failed', service: self.class.name, error: e.message
      failure(e.message)
    rescue StandardError => e
      logger.error 'Service unexpected error',
                   service: self.class.name,
                   error: e.message,
                   backtrace: e.backtrace.first(10)
      failure("An unexpected error occurred: #{e.message}")
    end
  end

  protected

  attr_reader :params

  # Override in subclasses to implement the main service logic
  # @return [Object] Service result data
  def perform
    raise NotImplementedError, 'Subclasses must implement #perform'
  end

  # Override in subclasses to validate input parameters
  # @raise [ValidationError] If parameters are invalid
  def validate_params!
    # Default implementation - override in subclasses
  end

  # Create a success result
  # @param data [Object] Result data
  # @param metadata [Hash] Additional metadata
  # @return [Result] Success result
  def success(data = nil, metadata: {})
    Result.new(success: true, data: data, metadata: metadata)
  end

  # Create a failure result
  # @param errors [String, Array] Error messages
  # @param metadata [Hash] Additional metadata
  # @return [Result] Failure result
  def failure(errors, metadata: {})
    Result.new(success: false, errors: errors, metadata: metadata)
  end

  # Validate required parameters
  # @param required_keys [Array<Symbol>] Required parameter keys
  # @raise [ValidationError] If required parameters are missing
  def require_params!(*required_keys)
    missing_keys = required_keys - params.keys
    if missing_keys.any?
      raise ValidationError, "Missing required parameters: #{missing_keys.join(', ')}"
    end
  end

  # Validate parameter types
  # @param validations [Hash] Hash of parameter => expected_class pairs
  # @raise [ValidationError] If parameter types don't match
  def validate_types!(validations)
    validations.each do |param_key, expected_class|
      next unless params.key?(param_key)

      value = params[param_key]
      next if value.nil? # Allow nil values

      unless value.is_a?(expected_class)
        raise ValidationError, "Parameter #{param_key} must be a #{expected_class}, got #{value.class}"
      end
    end
  end

  # Execute a block with error handling
  # @param error_message [String] Custom error message
  # @yield Block to execute
  # @return [Object] Block result
  # @raise [ProcessingError] If block raises an error
  def with_error_handling(error_message = 'Operation failed')
    yield
  rescue StandardError => e
    raise ProcessingError, "#{error_message}: #{e.message}"
  end

  # Log service execution time
  # @param operation_name [String] Name of the operation being timed
  # @yield Block to time
  # @return [Object] Block result
  def with_timing(operation_name = 'operation')
    start_time = Time.current
    result = yield
    duration = Time.current - start_time
    logger.info 'Service operation completed',
                service: self.class.name,
                operation: operation_name,
                duration_seconds: duration.round(3)
    result
  end

  # Get structured logger for this service
  def logger
    @logger ||= StructuredLogger.for_service(self.class.name)
  end

  private

  # Sanitize parameters for logging (remove sensitive data)
  def sanitized_params
    sensitive_keys = %i[password api_key token secret]
    params.except(*sensitive_keys)
  end
end
