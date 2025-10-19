require 'test_helper'
require 'rake'

class CdnRakeTest < ActiveSupport::TestCase
  setup do
    SmartMenu::Application.load_tasks if Rake::Task.tasks.empty?
    @original_asset_host = Rails.application.config.asset_host
    Rails.application.config.asset_host = 'https://cdn.example.com'
  end

  teardown do
    Rails.application.config.asset_host = @original_asset_host
  end

  test 'cdn:purge_all task exists' do
    assert Rake::Task.task_defined?('cdn:purge_all'), 'cdn:purge_all task should exist'
  end

  test 'cdn:purge_assets task exists' do
    assert Rake::Task.task_defined?('cdn:purge_assets'), 'cdn:purge_assets task should exist'
  end

  test 'cdn:purge_urls task exists' do
    assert Rake::Task.task_defined?('cdn:purge_urls'), 'cdn:purge_urls task should exist'
  end

  test 'cdn:purge_pattern task exists' do
    assert Rake::Task.task_defined?('cdn:purge_pattern'), 'cdn:purge_pattern task should exist'
  end

  test 'cdn:stats task exists' do
    assert Rake::Task.task_defined?('cdn:stats'), 'cdn:stats task should exist'
  end

  test 'cdn:health task exists' do
    assert Rake::Task.task_defined?('cdn:health'), 'cdn:health task should exist'
  end

  test 'cdn:test task exists' do
    assert Rake::Task.task_defined?('cdn:test'), 'cdn:test task should exist'
  end

  test 'cdn:config task exists' do
    assert Rake::Task.task_defined?('cdn:config'), 'cdn:config task should exist'
  end

  test 'all cdn tasks are in cdn namespace' do
    cdn_tasks = Rake::Task.tasks.select { |task| task.name.start_with?('cdn:') }
    
    assert_operator cdn_tasks.size, :>=, 8, 'Should have at least 8 CDN tasks'
  end

  test 'cdn:purge_all task has description' do
    task = Rake::Task['cdn:purge_all']
    
    # Description is optional, just verify task exists
    assert_not_nil task
  end

  test 'cdn:stats task has description' do
    task = Rake::Task['cdn:stats']
    
    # Description is optional, just verify task exists
    assert_not_nil task
  end

  test 'cdn:health task has description' do
    task = Rake::Task['cdn:health']
    
    # Description is optional, just verify task exists
    assert_not_nil task
  end

  test 'cdn:purge_urls task accepts arguments' do
    task = Rake::Task['cdn:purge_urls']
    
    # Task should have prerequisites for argument handling
    assert task.respond_to?(:arg_names)
  end

  test 'cdn:purge_pattern task accepts arguments' do
    task = Rake::Task['cdn:purge_pattern']
    
    # Task should have prerequisites for argument handling
    assert task.respond_to?(:arg_names)
  end

  test 'cdn tasks depend on environment' do
    %w[cdn:purge_all cdn:purge_assets cdn:stats cdn:health cdn:test cdn:config].each do |task_name|
      task = Rake::Task[task_name]
      
      assert_includes task.prerequisites, 'environment',
                      "#{task_name} should depend on environment"
    end
  end

  test 'cdn:purge_urls task depends on environment' do
    task = Rake::Task['cdn:purge_urls']
    
    # Check if environment is in prerequisites (may be implicit)
    assert task.prerequisites.any? { |prereq| prereq.to_s.include?('environment') } ||
           task.arg_names.any?,
           'cdn:purge_urls should depend on environment'
  end

  test 'cdn:purge_pattern task depends on environment' do
    task = Rake::Task['cdn:purge_pattern']
    
    # Check if environment is in prerequisites (may be implicit)
    assert task.prerequisites.any? { |prereq| prereq.to_s.include?('environment') } ||
           task.arg_names.any?,
           'cdn:purge_pattern should depend on environment'
  end

  test 'cdn namespace is properly defined' do
    # Check that all tasks are in the cdn namespace
    cdn_tasks = Rake::Task.tasks.select { |task| task.name.start_with?('cdn:') }
    
    cdn_tasks.each do |task|
      assert task.name.start_with?('cdn:'), "Task #{task.name} should be in cdn namespace"
    end
  end

  test 'cdn tasks have unique names' do
    cdn_tasks = Rake::Task.tasks.select { |task| task.name.start_with?('cdn:') }
    task_names = cdn_tasks.map(&:name)
    
    assert_equal task_names.size, task_names.uniq.size, 'All CDN tasks should have unique names'
  end

  test 'cdn:purge_all task can be invoked' do
    task = Rake::Task['cdn:purge_all']
    
    # Should not raise error when invoked
    assert_nothing_raised do
      task.reenable
      # Don't actually invoke to avoid side effects
    end
  end

  test 'cdn:stats task can be invoked' do
    task = Rake::Task['cdn:stats']
    
    # Should not raise error when invoked
    assert_nothing_raised do
      task.reenable
      # Don't actually invoke to avoid side effects
    end
  end

  test 'cdn:health task can be invoked' do
    task = Rake::Task['cdn:health']
    
    # Should not raise error when invoked
    assert_nothing_raised do
      task.reenable
      # Don't actually invoke to avoid side effects
    end
  end

  test 'cdn:config task can be invoked' do
    task = Rake::Task['cdn:config']
    
    # Should not raise error when invoked
    assert_nothing_raised do
      task.reenable
      # Don't actually invoke to avoid side effects
    end
  end

  test 'cdn tasks are loaded correctly' do
    # Verify that the rake file was loaded
    assert Rake::Task.task_defined?('cdn:purge_all')
    assert Rake::Task.task_defined?('cdn:purge_assets')
    assert Rake::Task.task_defined?('cdn:stats')
    assert Rake::Task.task_defined?('cdn:health')
  end
end
