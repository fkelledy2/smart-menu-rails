# frozen_string_literal: true

require 'test_helper'

class PerformanceAlertJobTest < ActiveSupport::TestCase
  test 'handles slow_response alert type without raising' do
    assert_nothing_raised do
      PerformanceAlertJob.new.perform(
        type: 'slow_response',
        severity: 'critical',
        endpoint: '/restaurants',
        response_time: 6000,
      )
    end
  end

  test 'handles server_error alert type without raising' do
    assert_nothing_raised do
      PerformanceAlertJob.new.perform(
        type: 'server_error',
        severity: 'high',
        endpoint: '/api/orders',
        status_code: 500,
      )
    end
  end

  test 'handles memory_leak alert type without raising' do
    assert_nothing_raised do
      PerformanceAlertJob.new.perform(
        type: 'memory_leak',
        severity: 'high',
        trend: 50,
      )
    end
  end

  test 'handles performance_regression alert type without raising' do
    assert_nothing_raised do
      PerformanceAlertJob.new.perform(
        type: 'performance_regression',
        severity: 'warning',
        endpoint: '/menus',
        increase: 25,
      )
    end
  end

  test 'handles unknown alert type without raising' do
    assert_nothing_raised do
      PerformanceAlertJob.new.perform(
        type: 'unknown_type',
        severity: 'low',
      )
    end
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      PerformanceAlertJob.perform_later(
        type: 'slow_response',
        severity: 'warning',
        endpoint: '/test',
        response_time: 2500,
      )
    end
  end
end
