require 'test_helper'
require 'rake'

class SecurityRakeTest < ActiveSupport::TestCase
  setup do
    SmartMenu::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'security:all task exists' do
    assert Rake::Task.task_defined?('security:all'), 'security:all task should exist'
  end

  test 'security:brakeman task exists' do
    assert Rake::Task.task_defined?('security:brakeman'), 'security:brakeman task should exist'
  end

  test 'security:bundle_audit task exists' do
    assert Rake::Task.task_defined?('security:bundle_audit'), 'security:bundle_audit task should exist'
  end

  test 'security:secrets_scan task exists' do
    assert Rake::Task.task_defined?('security:secrets_scan'), 'security:secrets_scan task should exist'
  end

  test 'security:report task exists' do
    assert Rake::Task.task_defined?('security:report'), 'security:report task should exist'
  end

  test 'security:ci task exists' do
    assert Rake::Task.task_defined?('security:ci'), 'security:ci task should exist'
  end

  test 'security:all has correct dependencies' do
    task = Rake::Task['security:all']
    expected_dependencies = ['brakeman', 'bundle_audit', 'secrets_scan']
    
    assert_equal expected_dependencies.sort, task.prerequisites.sort,
                 'security:all should depend on brakeman, bundle_audit, and secrets_scan'
  end
end
