require 'test_helper'

class BaseServiceSimpleTest < ActiveSupport::TestCase
  # Simple test service for basic functionality
  class SimpleTestService < BaseService
    protected

    def validate_params!
      require_params!(:required_param)
    end

    def perform
      if params[:should_fail]
        raise ProcessingError, 'Intentional failure'
      end

      { result: 'success', input: params[:required_param] }
    end
  end

  # Service for testing error handling
  class ErrorTestService < BaseService
    protected

    def perform
      case params[:error_type]
      when 'validation'
        raise ValidationError, 'Custom validation error'
      when 'processing'
        raise ProcessingError, 'Custom processing error'
      when 'standard'
        raise StandardError, 'Standard error'
      else
        { success: true }
      end
    end
  end

  # Result class tests
  test 'Result should initialize with success state' do
    success_result = BaseService::Result.new(success: true, data: 'test_data')

    assert success_result.success?
    assert_not success_result.failure?
    assert_equal 'test_data', success_result.data
    assert_equal [], success_result.errors
    assert_equal({}, success_result.metadata)
  end

  test 'Result should initialize with failure state' do
    failure_result = BaseService::Result.new(success: false, errors: %w[error1 error2])

    assert_not failure_result.success?
    assert failure_result.failure?
    assert_nil failure_result.data
    assert_equal %w[error1 error2], failure_result.errors
  end

  test 'Result should handle single error as array' do
    result = BaseService::Result.new(success: false, errors: 'single_error')

    assert_equal ['single_error'], result.errors
    assert_equal ['single_error'], result.error_messages
    assert_equal 'single_error', result.first_error
  end

  test 'Result should handle nil errors' do
    result = BaseService::Result.new(success: false, errors: nil)

    assert_equal [], result.errors
    assert_equal [], result.error_messages
    assert_nil result.first_error
  end

  test 'Result should store metadata' do
    metadata = { attempt: 2, duration: 1.5 }
    result = BaseService::Result.new(success: true, metadata: metadata)

    assert_equal metadata, result.metadata
  end

  # Basic service functionality tests
  test 'call returns success result for valid input' do
    result = SimpleTestService.call(required_param: 'test')

    assert result.success?
    assert_not result.failure?
    assert_equal 'success', result.data[:result]
    assert_equal 'test', result.data[:input]
  end

  test 'call returns failure result for missing required params' do
    result = SimpleTestService.call(optional_param: 'test')

    assert_not result.success?
    assert result.failure?
    assert_includes result.first_error, 'Missing required parameters'
  end

  test 'call returns failure result for processing errors' do
    result = SimpleTestService.call(required_param: 'test', should_fail: true)

    assert_not result.success?
    assert_includes result.first_error, 'Intentional failure'
  end

  test 'call! returns data on success' do
    data = SimpleTestService.call!(required_param: 'test')

    assert_equal 'success', data[:result]
    assert_equal 'test', data[:input]
  end

  test 'call! raises error on failure' do
    assert_raises(BaseService::ProcessingError) do
      SimpleTestService.call!(required_param: 'test', should_fail: true)
    end
  end

  # Error handling tests
  test 'should handle ValidationError specifically' do
    result = ErrorTestService.call(error_type: 'validation')

    assert result.failure?
    assert_equal 'Custom validation error', result.first_error
  end

  test 'should handle ProcessingError specifically' do
    result = ErrorTestService.call(error_type: 'processing')

    assert result.failure?
    assert_equal 'Custom processing error', result.first_error
  end

  test 'should handle StandardError generically' do
    result = ErrorTestService.call(error_type: 'standard')

    assert result.failure?
    assert_includes result.first_error, 'An unexpected error occurred'
    assert_includes result.first_error, 'Standard error'
  end

  # Parameter validation helper tests
  test 'require_params! should work correctly' do
    service = SimpleTestService.new(required_param: 'test', extra: 'data')

    # Should not raise error when required param is present
    assert_nothing_raised do
      service.send(:require_params!, :required_param)
    end

    # Should raise error when required param is missing
    assert_raises(BaseService::ValidationError) do
      service.send(:require_params!, :missing_param)
    end
  end

  test 'validate_types! should work correctly' do
    service = SimpleTestService.new(required_param: 'test', string_param: 'test', number_param: 42)

    # Should not raise error for correct types
    assert_nothing_raised do
      service.send(:validate_types!, string_param: String, number_param: Integer)
    end

    # Should raise error for incorrect types
    assert_raises(BaseService::ValidationError) do
      service.send(:validate_types!, string_param: Integer)
    end
  end

  test 'validate_types! should allow nil values' do
    service = SimpleTestService.new(required_param: 'test', string_param: nil)

    # Should not raise error for nil values
    assert_nothing_raised do
      service.send(:validate_types!, string_param: String)
    end
  end

  # Success and failure result creation tests
  test 'success should create success result with data' do
    service = SimpleTestService.new(required_param: 'test')
    result = service.send(:success, { data: 'test' })

    assert result.success?
    assert_equal({ data: 'test' }, result.data)
  end

  test 'success should create success result with metadata' do
    service = SimpleTestService.new(required_param: 'test')
    result = service.send(:success, 'data', metadata: { version: 1 })

    assert result.success?
    assert_equal 'data', result.data
    assert_equal({ version: 1 }, result.metadata)
  end

  test 'failure should create failure result with errors' do
    service = SimpleTestService.new(required_param: 'test')
    result = service.send(:failure, 'Error occurred')

    assert result.failure?
    assert_equal ['Error occurred'], result.errors
  end

  test 'failure should create failure result with multiple errors' do
    service = SimpleTestService.new(required_param: 'test')
    result = service.send(:failure, ['Error 1', 'Error 2'])

    assert result.failure?
    assert_equal ['Error 1', 'Error 2'], result.errors
  end

  test 'failure should create failure result with metadata' do
    service = SimpleTestService.new(required_param: 'test')
    result = service.send(:failure, 'Error', metadata: { retry_count: 3 })

    assert result.failure?
    assert_equal({ retry_count: 3 }, result.metadata)
  end

  # Exception hierarchy tests
  test 'should define proper exception hierarchy' do
    assert BaseService::Error < StandardError
    assert BaseService::ValidationError < BaseService::Error
    assert BaseService::ProcessingError < BaseService::Error
  end

  # Instance method access tests
  test 'should provide access to params in instance' do
    service = SimpleTestService.new(required_param: 'test', extra: 'data')

    assert_equal 'test', service.send(:params)[:required_param]
    assert_equal 'data', service.send(:params)[:extra]
  end

  # Edge cases
  test 'should handle empty parameters' do
    result = SimpleTestService.call

    assert result.failure?
    assert_includes result.first_error, 'Missing required parameters'
  end

  test 'should handle complex data structures in results' do
    class ComplexDataService < BaseService
      protected

      def perform
        {
          users: [{ id: 1, name: 'John' }, { id: 2, name: 'Jane' }],
          metadata: { total: 2, page: 1 },
          nested: { deep: { value: 'test' } },
        }
      end
    end

    result = ComplexDataService.call

    assert result.success?
    assert_equal 2, result.data[:users].length
    assert_equal 'John', result.data[:users][0][:name]
    assert_equal 'test', result.data[:nested][:deep][:value]
  end

  # Integration test
  test 'should work with real-world service pattern' do
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
        {
          id: rand(1000),
          name: params[:name],
          email: params[:email],
          age: params[:age],
          created_at: Time.current,
        }
      end
    end

    result = UserCreationService.call(
      name: 'John Doe',
      email: 'john@example.com',
      age: 30,
    )

    assert result.success?
    assert_equal 'John Doe', result.data[:name]
    assert_equal 'john@example.com', result.data[:email]
    assert_equal 30, result.data[:age]
    assert result.data[:id].is_a?(Integer)
    assert result.data[:created_at].is_a?(Time)
  end

  test 'integration service should validate email format' do
    class UserCreationService < BaseService
      protected

      def validate_params!
        require_params!(:name, :email)
        unless params[:email].include?('@')
          raise ValidationError, 'Invalid email format'
        end
      end

      def perform
        { user: params[:name] }
      end
    end

    result = UserCreationService.call(name: 'John', email: 'invalid-email')

    assert result.failure?
    assert_equal 'Invalid email format', result.first_error
  end
end
