# frozen_string_literal: true

require 'test_helper'
require 'rake'

class BrowserCacheRakeTest < ActiveSupport::TestCase
  setup do
    SmartMenu::Application.load_tasks if Rake::Task.tasks.empty?
    Rails.cache.clear
  end

  teardown do
    Rails.cache.clear
  end

  # Task existence tests
  test 'browser_cache:stats task exists' do
    assert Rake::Task.task_defined?('browser_cache:stats')
  end

  test 'browser_cache:health task exists' do
    assert Rake::Task.task_defined?('browser_cache:health')
  end

  test 'browser_cache:reset_stats task exists' do
    assert Rake::Task.task_defined?('browser_cache:reset_stats')
  end

  test 'browser_cache:test task exists' do
    assert Rake::Task.task_defined?('browser_cache:test')
  end

  test 'browser_cache:config task exists' do
    assert Rake::Task.task_defined?('browser_cache:config')
  end

  test 'browser_cache:warm task exists' do
    assert Rake::Task.task_defined?('browser_cache:warm')
  end

  test 'browser_cache:analyze task exists' do
    assert Rake::Task.task_defined?('browser_cache:analyze')
  end

  # Task execution tests
  test 'browser_cache:stats task runs without error' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['browser_cache:stats'].execute
      end
    end
  end

  test 'browser_cache:health task runs without error' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['browser_cache:health'].execute
      end
    end
  end

  test 'browser_cache:reset_stats task runs without error' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['browser_cache:reset_stats'].execute
      end
    end
  end

  test 'browser_cache:test task runs without error' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['browser_cache:test'].execute
      end
    end
  end

  test 'browser_cache:config task runs without error' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['browser_cache:config'].execute
      end
    end
  end

  test 'browser_cache:warm task runs without error' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['browser_cache:warm'].execute
      end
    end
  end

  test 'browser_cache:analyze task runs without error' do
    assert_nothing_raised do
      capture_io do
        Rake::Task['browser_cache:analyze'].execute
      end
    end
  end

  # Task output tests
  test 'browser_cache:stats displays statistics' do
    output = capture_io do
      Rake::Task['browser_cache:stats'].execute
    end.join
    
    assert_includes output, 'Browser Cache Statistics'
    assert_includes output, 'Total Requests'
  end

  test 'browser_cache:health displays health status' do
    output = capture_io do
      Rake::Task['browser_cache:health'].execute
    end.join
    
    assert_includes output, 'Browser Cache Health Check'
    assert_includes output, 'Status'
  end

  test 'browser_cache:config displays configuration' do
    output = capture_io do
      Rake::Task['browser_cache:config'].execute
    end.join
    
    assert_includes output, 'Browser Cache Configuration'
    assert_includes output, 'Environment'
  end

  test 'browser_cache:test displays test results' do
    output = capture_io do
      Rake::Task['browser_cache:test'].execute
    end.join
    
    assert_includes output, 'Browser Cache Configuration Test'
    assert_includes output, 'BrowserCacheService'
  end

  test 'browser_cache:analyze displays performance analysis' do
    output = capture_io do
      Rake::Task['browser_cache:analyze'].execute
    end.join
    
    assert_includes output, 'Browser Cache Performance Analysis'
    assert_includes output, 'Overall Performance'
  end

  # Task functionality tests
  test 'browser_cache:reset_stats clears statistics' do
    # Add some stats
    request = ActionDispatch::TestRequest.create
    response = ActionDispatch::Response.new
    response.status = 200
    response.content_type = 'text/html'
    BrowserCacheAnalyticsService.track_request(request, response)
    
    # Verify stats exist
    summary_before = BrowserCacheAnalyticsService.performance_summary
    assert_operator summary_before[:total_requests], :>, 0
    
    # Reset
    capture_io do
      Rake::Task['browser_cache:reset_stats'].execute
    end
    
    # Verify stats are cleared
    summary_after = BrowserCacheAnalyticsService.performance_summary
    assert_equal 0, summary_after[:total_requests]
  end

  test 'browser_cache:test verifies service initialization' do
    output = capture_io do
      Rake::Task['browser_cache:test'].execute
    end.join
    
    assert_includes output, 'BrowserCacheService initialized'
    assert_includes output, 'BrowserCacheAnalyticsService initialized'
    assert_includes output, 'All tests passed'
  end

  # Task namespace tests
  test 'all browser_cache tasks are in browser_cache namespace' do
    browser_cache_tasks = Rake::Task.tasks.select { |task| task.name.start_with?('browser_cache:') }
    
    assert_operator browser_cache_tasks.size, :>=, 7, 'Should have at least 7 browser_cache tasks'
  end

  # Task dependencies tests
  test 'browser_cache tasks depend on environment' do
    task = Rake::Task['browser_cache:stats']
    
    assert_includes task.prerequisites, 'environment'
  end

  private

  def capture_io
    require 'stringio'
    
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new
    
    yield
    
    [$stdout.string, $stderr.string]
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end
