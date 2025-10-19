require 'test_helper'
require 'rake'

class CodeQualityRakeTest < ActiveSupport::TestCase
  setup do
    SmartMenu::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test 'code_quality:all task exists' do
    assert Rake::Task.task_defined?('code_quality:all'), 'code_quality:all task should exist'
  end

  test 'code_quality:rubocop task exists' do
    assert Rake::Task.task_defined?('code_quality:rubocop'), 'code_quality:rubocop task should exist'
  end

  test 'code_quality:rubocop_check task exists' do
    assert Rake::Task.task_defined?('code_quality:rubocop_check'), 'code_quality:rubocop_check task should exist'
  end

  test 'code_quality:brakeman task exists' do
    assert Rake::Task.task_defined?('code_quality:brakeman'), 'code_quality:brakeman task should exist'
  end

  test 'code_quality:bundle_audit task exists' do
    assert Rake::Task.task_defined?('code_quality:bundle_audit'), 'code_quality:bundle_audit task should exist'
  end

  test 'code_quality:report task exists' do
    assert Rake::Task.task_defined?('code_quality:report'), 'code_quality:report task should exist'
  end

  test 'code_quality:ci task exists' do
    assert Rake::Task.task_defined?('code_quality:ci'), 'code_quality:ci task should exist'
  end

  test 'code_quality:all has correct dependencies' do
    task = Rake::Task['code_quality:all']
    expected_dependencies = ['rubocop', 'brakeman', 'bundle_audit']
    
    assert_equal expected_dependencies.sort, task.prerequisites.sort,
                 'code_quality:all should depend on rubocop, brakeman, and bundle_audit'
  end
end
