# frozen_string_literal: true

require 'test_helper'

class PerformanceTrackingJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def perform_job(**overrides)
    attrs = {
      endpoint: '/restaurants',
      response_time: 100,
      memory_usage: 50.0,
      status_code: 200,
      timestamp: Time.current,
    }.merge(overrides)
    PerformanceTrackingJob.new.perform(**attrs)
  end

  test 'creates performance metric record' do
    assert_difference 'PerformanceMetric.count', 1 do
      perform_job
    end
  end

  test 'records the endpoint correctly' do
    perform_job(endpoint: '/menus')
    assert_equal '/menus', PerformanceMetric.last.endpoint
  end

  test 'records user_id when provided' do
    user = users(:one)
    perform_job(user_id: user.id)
    assert_equal user.id, PerformanceMetric.last.user_id
  end

  test 'does not raise when status is 500' do
    assert_nothing_raised do
      perform_job(status_code: 500)
    end
  end

  test 'does not raise when response_time is very high' do
    assert_nothing_raised do
      perform_job(response_time: 10_000)
    end
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      PerformanceTrackingJob.perform_later(
        endpoint: '/test',
        response_time: 200,
        memory_usage: 40.0,
        status_code: 200,
        timestamp: Time.current,
      )
    end
  end
end
