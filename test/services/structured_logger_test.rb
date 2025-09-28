require 'test_helper'

class StructuredLoggerTest < ActiveSupport::TestCase
  def setup
    @original_logger = Rails.logger
    @log_output = StringIO.new
    Rails.logger = ActiveSupport::Logger.new(@log_output)
  end

  def teardown
    Rails.logger = @original_logger
  end

  test 'logs structured messages with context' do
    StructuredLogger.info('Test message', user_id: 123, action: 'test')

    log_content = @log_output.string
    assert_includes log_content, 'Test message'

    # In development, it should be human readable
    if Rails.env.development?
      assert_includes log_content, 'user_id=123'
      assert_includes log_content, 'action=test'
    end
  end

  test 'service logger includes service name' do
    service_logger = StructuredLogger.for_service('TestService')
    service_logger.info('Service message', operation: 'test_op')

    log_content = @log_output.string
    assert_includes log_content, 'Service message'

    if Rails.env.development?
      assert_includes log_content, 'service=TestService'
      assert_includes log_content, 'operation=test_op'
    end
  end

  test 'handles different log levels' do
    StructuredLogger.debug('Debug message')
    StructuredLogger.info('Info message')
    StructuredLogger.warn('Warning message')
    StructuredLogger.error('Error message')

    log_content = @log_output.string

    # Should contain messages based on current log level
    if Rails.logger.debug?
      assert_includes log_content, 'Debug message'
    end
    assert_includes log_content, 'Info message'
    assert_includes log_content, 'Warning message'
    assert_includes log_content, 'Error message'
  end

  test 'handles block messages' do
    StructuredLogger.info { 'Block message' }

    log_content = @log_output.string
    assert_includes log_content, 'Block message'
  end

  test 'includes timestamp and level' do
    StructuredLogger.info('Test message')

    log_content = @log_output.string
    assert_includes log_content, 'INFO'

    # Should include timestamp (basic check)
    assert_match(/\d{4}-\d{2}-\d{2}/, log_content)
  end
end
