require 'test_helper'

class BaseServiceTest < ActiveSupport::TestCase
  # Test service implementations for testing BaseService functionality
  class TestService < BaseService
    protected

    def perform
      require_params!(:required_param)
      validate_types!(optional_param: String)

      if params[:should_fail]
        raise ProcessingError, 'Intentional failure'
      end

      { result: 'success', input: params[:required_param] }
    end
  end

  class ValidationTestService < BaseService
    protected

    def validate_params!
      require_params!(:name, :email)
      validate_types!(name: String, email: String, age: Integer)
      
      if params[:name]&.length&.< 2
        raise ValidationError, 'Name must be at least 2 characters'
      end
    end

    def perform
      { user: params.slice(:name, :email, :age) }
    end
  end

  class ErrorHandlingService < BaseService
    protected

    def perform
      case params[:error_type]
      when 'validation'
        raise ValidationError, 'Custom validation error'
      when 'processing'
        raise ProcessingError, 'Custom processing error'
      when 'standard'
        raise StandardError, 'Standard error'
      when 'with_handling'
        with_error_handling('Database operation failed') do
          raise ActiveRecord::RecordNotFound, 'Record not found'
        end
      else
        { success: true }
      end
    end
  end

  class TimingTestService < BaseService
    protected

    def perform
      with_timing('database_query') do
        sleep(0.01) # Simulate some work
        { query_result: 'data' }
      end
    end
  end

  class LoggingTestService < BaseService
    protected

    def perform
      logger.info 'Custom log message'
      { logged: true }
    end
  end

  class NoPerformService < BaseService
    # Intentionally doesn't override perform to test NotImplementedError
  end

  # Result class tests
  test "Result should initialize with success state" do
    success_result = BaseService::Result.new(success: true, data: 'test_data')
    
    assert success_result.success?
    assert_not success_result.failure?
    assert_equal 'test_data', success_result.data
    assert_equal [], success_result.errors
    assert_equal({}, success_result.metadata)
  end

  test "Result should initialize with failure state" do
    failure_result = BaseService::Result.new(success: false, errors: ['error1', 'error2'])
    
    assert_not failure_result.success?
    assert failure_result.failure?
    assert_nil failure_result.data
    assert_equal ['error1', 'error2'], failure_result.errors
  end

  test "Result should handle single error as array" do
    result = BaseService::Result.new(success: false, errors: 'single_error')
    
    assert_equal ['single_error'], result.errors
    assert_equal ['single_error'], result.error_messages
    assert_equal 'single_error', result.first_error
  end

  test "Result should handle nil errors" do
    result = BaseService::Result.new(success: false, errors: nil)
    
    assert_equal [], result.errors
    assert_equal [], result.error_messages
    assert_nil result.first_error
  end

  test "Result should store metadata" do
    metadata = { attempt: 2, duration: 1.5 }
    result = BaseService::Result.new(success: true, metadata: metadata)
    
    assert_equal metadata, result.metadata
  end

  # Basic service functionality tests
  test 'call returns success result for valid input' do
    result = TestService.call(required_param: 'test')

    assert result.success?
    assert_not result.failure?
    assert_equal 'success', result.data[:result]
    assert_equal 'test', result.data[:input]
  end

  test 'call returns failure result for missing required params' do
    result = TestService.call(optional_param: 'test')

    assert_not result.success?
    assert result.failure?
    assert_includes result.first_error, 'Missing required parameters'
  end

  test 'call returns failure result for invalid param types' do
    result = TestService.call(required_param: 'test', optional_param: 123)

    assert_not result.success?
    assert_includes result.first_error, 'must be a String'
  end

  test 'call returns failure result for processing errors' do
    result = TestService.call(required_param: 'test', should_fail: true)

    assert_not result.success?
    assert_includes result.first_error, 'Intentional failure'
  end

  test 'call! returns data on success' do
    data = TestService.call!(required_param: 'test')

    assert_equal 'success', data[:result]
    assert_equal 'test', data[:input]
  end

  test 'call! raises error on failure' do
    assert_raises(BaseService::ProcessingError) do
      TestService.call!(required_param: 'test', should_fail: true)
    end
  end

  # Parameter validation tests
  test "require_params! should validate multiple required parameters" do
    result = ValidationTestService.call(name: 'John')
    
    assert result.failure?
    assert_includes result.first_error, 'Missing required parameters: email'
  end

  test "require_params! should pass when all required parameters present" do
    result = ValidationTestService.call(name: 'John', email: 'john@example.com')
    
    assert result.success?
    assert_equal 'John', result.data[:user][:name]
    assert_equal 'john@example.com', result.data[:user][:email]
  end

  test "validate_types! should validate parameter types" do
    result = ValidationTestService.call(name: 'John', email: 'john@example.com', age: 'thirty')
    
    assert result.failure?
    assert_includes result.first_error, 'Parameter age must be a Integer'
  end

  test "validate_types! should allow nil values" do
    result = ValidationTestService.call(name: 'John', email: 'john@example.com', age: nil)
    
    assert result.success?
    assert_nil result.data[:user][:age]
  end

  test "validate_types! should pass with correct types" do
    result = ValidationTestService.call(name: 'John', email: 'john@example.com', age: 30)
    
    assert result.success?
    assert_equal 30, result.data[:user][:age]
  end

  test "custom validation in validate_params! should work" do
    result = ValidationTestService.call(name: 'J', email: 'john@example.com')
    
    assert result.failure?
    assert_includes result.first_error, 'Name must be at least 2 characters'
  end

  # Error handling tests
  test "should handle ValidationError specifically" do
    result = ErrorHandlingService.call(error_type: 'validation')
    
    assert result.failure?
    assert_equal 'Custom validation error', result.first_error
  end

  test "should handle ProcessingError specifically" do
    result = ErrorHandlingService.call(error_type: 'processing')
    
    assert result.failure?
    assert_equal 'Custom processing error', result.first_error
  end

  test "should handle StandardError generically" do
    result = ErrorHandlingService.call(error_type: 'standard')
    
    assert result.failure?
    assert_includes result.first_error, 'An unexpected error occurred'
    assert_includes result.first_error, 'Standard error'
  end

  test "with_error_handling should wrap errors in ProcessingError" do
    result = ErrorHandlingService.call(error_type: 'with_handling')
    
    assert result.failure?
    assert_includes result.first_error, 'Database operation failed: Record not found'
  end

  test "with_error_handling should use default error message" do
    service = ErrorHandlingService.new
    
    assert_raises(BaseService::ProcessingError) do
      service.send(:with_error_handling) do
        raise 'Test error'
      end
    end
  end

  # Success and failure result creation tests
  test "success should create success result with data" do
    service = TestService.new(required_param: 'test')
    result = service.send(:success, { data: 'test' })
    
    assert result.success?
    assert_equal({ data: 'test' }, result.data)
  end

  test "success should create success result with metadata" do
    service = TestService.new(required_param: 'test')
    result = service.send(:success, 'data', metadata: { version: 1 })
    
    assert result.success?
    assert_equal 'data', result.data
    assert_equal({ version: 1 }, result.metadata)
  end

  test "failure should create failure result with errors" do
    service = TestService.new(required_param: 'test')
    result = service.send(:failure, 'Error occurred')
    
    assert result.failure?
    assert_equal ['Error occurred'], result.errors
  end

  test "failure should create failure result with multiple errors" do
    service = TestService.new(required_param: 'test')
    result = service.send(:failure, ['Error 1', 'Error 2'])
    
    assert result.failure?
    assert_equal ['Error 1', 'Error 2'], result.errors
  end

  test "failure should create failure result with metadata" do
    service = TestService.new(required_param: 'test')
    result = service.send(:failure, 'Error', metadata: { retry_count: 3 })
    
    assert result.failure?
    assert_equal({ retry_count: 3 }, result.metadata)
  end

  # Timing functionality tests
  test "with_timing should execute block and log duration" do
    log_output = capture_logs do
      result = TimingTestService.call
      assert result.success?
      assert_equal 'data', result.data[:query_result]
    end
    
    assert_includes log_output, 'Service operation completed'
    assert_includes log_output, 'database_query'
    assert_includes log_output, 'duration_seconds'
  end

  test "with_timing should use default operation name" do
    service = TestService.new(required_param: 'test')
    
    log_output = capture_logs do
      result = service.send(:with_timing) { 'result' }
      assert_equal 'result', result
    end
    
    assert_includes log_output, 'operation'
  end

  # Logging tests
  test "should use structured logger" do
    log_output = capture_logs do
      result = LoggingTestService.call
      assert result.success?
    end
    
    assert_includes log_output, 'Custom log message'
  end

  test "should log service start and completion" do
    log_output = capture_logs do
      TestService.call(required_param: 'test')
    end
    
    assert_includes log_output, 'Service starting'
    assert_includes log_output, 'Service completed successfully'
  end

  test "should log validation failures" do
    log_output = capture_logs do
      TestService.call(optional_param: 'test')
    end
    
    assert_includes log_output, 'Service validation failed'
  end

  test "should log processing failures" do
    log_output = capture_logs do
      TestService.call(required_param: 'test', should_fail: true)
    end
    
    assert_includes log_output, 'Service processing failed'
  end

  test "should log unexpected errors with backtrace" do
    log_output = capture_logs do
      ErrorHandlingService.call(error_type: 'standard')
    end
    
    assert_includes log_output, 'Service unexpected error'
    assert_includes log_output, 'backtrace'
  end

  # Parameter sanitization tests
  test "should sanitize sensitive parameters in logs" do
    class SensitiveParamService < BaseService
      protected
      def perform
        { result: 'success' }
      end
    end
    
    log_output = capture_logs do
      SensitiveParamService.call(
        username: 'user',
        password: 'secret123',
        api_key: 'key123',
        token: 'token123',
        secret: 'secret456'
      )
    end
    
    assert_includes log_output, 'username'
    assert_not_includes log_output, 'secret123'
    assert_not_includes log_output, 'key123'
    assert_not_includes log_output, 'token123'
    assert_not_includes log_output, 'secret456'
  end

  # Exception hierarchy tests
  test "should define proper exception hierarchy" do
    assert BaseService::Error < StandardError
    assert BaseService::ValidationError < BaseService::Error
    assert BaseService::ProcessingError < BaseService::Error
  end

  # NotImplementedError test
  test "should raise NotImplementedError when perform is not implemented" do
    result = NoPerformService.call
    
    assert result.failure?
    assert_includes result.first_error, 'An unexpected error occurred'
  end

  # Instance method access tests
  test "should provide access to params in instance" do
    service = TestService.new(required_param: 'test', extra: 'data')
    
    assert_equal 'test', service.send(:params)[:required_param]
    assert_equal 'data', service.send(:params)[:extra]
  end

  # Edge cases and error scenarios
  test "should handle empty parameters" do
    result = TestService.call
    
    assert result.failure?
    assert_includes result.first_error, 'Missing required parameters'
  end

  test "should handle nil parameters gracefully" do
    # This tests the parameter validation when params contain nil values
    result = ValidationTestService.call(name: nil, email: 'test@example.com')
    
    assert result.failure?
    # Should fail on name validation since nil.length will raise an error
  end

  test "should handle complex data structures in results" do
    class ComplexDataService < BaseService
      protected
      def perform
        {
          users: [{ id: 1, name: 'John' }, { id: 2, name: 'Jane' }],
          metadata: { total: 2, page: 1 },
          nested: { deep: { value: 'test' } }
        }
      end
    end
    
    result = ComplexDataService.call
    
    assert result.success?
    assert_equal 2, result.data[:users].length
    assert_equal 'John', result.data[:users][0][:name]
    assert_equal 'test', result.data[:nested][:deep][:value]
  end

  # Integration tests
  test "should work with real-world service pattern" do
    class UserCreationService < BaseService
      protected
      
      def validate_params!
        require_params!(:name, :email)
        validate_types!(name: String, email: String, age: Integer)
        
        unless params[:email].include?('@')
          raise ValidationError, 'Invalid email format'
        end
      end
      
      def perform
        with_timing('user_creation') do
          with_error_handling('User creation failed') do
            user_data = {
              id: rand(1000),
              name: params[:name],
              email: params[:email],
              age: params[:age],
              created_at: Time.current
            }
            
            logger.info 'User created successfully', user_id: user_data[:id]
            user_data
          end
        end
      end
    end
    
    log_output = capture_logs do
      result = UserCreationService.call(
        name: 'John Doe',
        email: 'john@example.com',
        age: 30
      )
      
      assert result.success?
      assert_equal 'John Doe', result.data[:name]
      assert_equal 'john@example.com', result.data[:email]
      assert_equal 30, result.data[:age]
      assert result.data[:id].is_a?(Integer)
      assert result.data[:created_at].is_a?(Time)
    end
    
    assert_includes log_output, 'Service starting'
    assert_includes log_output, 'User created successfully'
    assert_includes log_output, 'Service operation completed'
    assert_includes log_output, 'user_creation'
    assert_includes log_output, 'Service completed successfully'
  end

  private

  def capture_logs
    original_logger = Rails.logger
    log_output = StringIO.new
    Rails.logger = Logger.new(log_output)
    
    # Mock StructuredLogger to use a compatible logger
    mock_logger = Object.new
    mock_logger.define_singleton_method(:info) do |message = nil, **context|
      log_message = [message, context.map { |k, v| "#{k}=#{v}" }].flatten.compact.join(' ')
      Rails.logger.info(log_message)
    end
    mock_logger.define_singleton_method(:warn) do |message = nil, **context|
      log_message = [message, context.map { |k, v| "#{k}=#{v}" }].flatten.compact.join(' ')
      Rails.logger.warn(log_message)
    end
    mock_logger.define_singleton_method(:error) do |message = nil, **context|
      log_message = [message, context.map { |k, v| "#{k}=#{v}" }].flatten.compact.join(' ')
      Rails.logger.error(log_message)
    end
    
    StructuredLogger.stub(:for_service, ->(_service_name) { mock_logger }) do
      yield
    end
    
    log_output.string
  ensure
    Rails.logger = original_logger
  end
end
