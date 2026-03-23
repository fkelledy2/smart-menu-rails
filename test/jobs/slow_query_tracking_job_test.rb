# frozen_string_literal: true

require 'test_helper'

class SlowQueryTrackingJobTest < ActiveSupport::TestCase
  def perform_job(**overrides)
    attrs = {
      sql: 'SELECT * FROM restaurants WHERE id = 1',
      duration: 1000,
      timestamp: Time.current,
    }.merge(overrides)
    SlowQueryTrackingJob.new.perform(**attrs)
  end

  test 'creates slow query record' do
    assert_difference 'SlowQuery.count', 1 do
      perform_job
    end
  end

  test 'records the sql correctly' do
    perform_job(sql: 'SELECT * FROM menus')
    assert_equal 'SELECT * FROM menus', SlowQuery.last.sql
  end

  test 'records duration correctly' do
    perform_job(duration: 2500)
    assert_equal 2500, SlowQuery.last.duration
  end

  test 'handles backtrace array' do
    backtrace = ['line1', 'line2', 'line3']
    perform_job(backtrace: backtrace)
    assert_equal backtrace.join("\n"), SlowQuery.last.backtrace
  end

  test 'does not raise for very slow query' do
    assert_nothing_raised do
      perform_job(duration: 11_000)
    end
  end

  test 'does not raise for slow query over 5s' do
    assert_nothing_raised do
      perform_job(duration: 6000)
    end
  end

  test 'enqueues without raising' do
    assert_nothing_raised do
      SlowQueryTrackingJob.perform_later(
        sql: 'SELECT 1',
        duration: 100,
        timestamp: Time.current,
      )
    end
  end
end
