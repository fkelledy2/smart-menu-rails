require 'test_helper'

class BaseServiceTest < ActiveSupport::TestCase
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

  test 'result object provides error information' do
    result = BaseService::Result.new(
      success: false,
      errors: ['Error 1', 'Error 2'],
      metadata: { attempt: 1 },
    )

    assert_not result.success?
    assert result.failure?
    assert_equal ['Error 1', 'Error 2'], result.error_messages
    assert_equal 'Error 1', result.first_error
    assert_equal 1, result.metadata[:attempt]
  end

  test 'result object handles single error' do
    result = BaseService::Result.new(success: false, errors: 'Single error')

    assert_equal ['Single error'], result.error_messages
    assert_equal 'Single error', result.first_error
  end
end
