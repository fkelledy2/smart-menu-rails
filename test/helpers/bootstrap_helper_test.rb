# frozen_string_literal: true

require 'test_helper'

class BootstrapHelperTest < ActionView::TestCase
  include BootstrapHelper

  # Bootstrap class mapping tests
  test 'should return correct class for success flash type' do
    assert_equal 'alert-success', bootstrap_class_for('success')
    assert_equal 'alert-success', bootstrap_class_for(:success)
  end

  test 'should return correct class for error flash type' do
    assert_equal 'alert-danger', bootstrap_class_for('error')
    assert_equal 'alert-danger', bootstrap_class_for(:error)
  end

  test 'should return correct class for alert flash type' do
    assert_equal 'alert-warning', bootstrap_class_for('alert')
    assert_equal 'alert-warning', bootstrap_class_for(:alert)
  end

  test 'should return correct class for notice flash type' do
    assert_equal 'alert-primary', bootstrap_class_for('notice')
    assert_equal 'alert-primary', bootstrap_class_for(:notice)
  end

  test 'should return original flash type for unknown types' do
    assert_equal 'custom', bootstrap_class_for('custom')
    assert_equal 'info', bootstrap_class_for(:info)
    assert_equal 'warning', bootstrap_class_for('warning')
  end

  test 'should handle nil flash type' do
    assert_equal '', bootstrap_class_for(nil)
  end

  test 'should handle empty string flash type' do
    assert_equal '', bootstrap_class_for('')
  end

  test 'should handle numeric flash type' do
    assert_equal '123', bootstrap_class_for(123)
  end

  # Edge cases
  test 'should handle mixed case flash types' do
    assert_equal 'Success', bootstrap_class_for('Success')
    assert_equal 'ERROR', bootstrap_class_for('ERROR')
  end

  test 'should handle flash types with spaces' do
    assert_equal 'flash message', bootstrap_class_for('flash message')
  end
end
