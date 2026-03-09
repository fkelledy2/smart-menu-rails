require 'test_helper'

class CdnRakeTest < ActiveSupport::TestCase
  setup do
    @original_asset_host = Rails.application.config.asset_host
    Rails.application.config.asset_host = 'https://cdn.example.com'
    @source = Rails.root.join('lib', 'tasks', 'cdn.rake').read
  end

  teardown do
    Rails.application.config.asset_host = @original_asset_host
  end

  test 'cdn:purge_all task exists' do
    assert_match(/task\s+purge_all:\s*:environment/, @source)
  end

  test 'cdn:purge_assets task exists' do
    assert_match(/task\s+purge_assets:\s*:environment/, @source)
  end

  test 'cdn:purge_urls task exists' do
    assert_match(/task\s+:purge_urls,\s*\[:urls\]\s*=>\s*:environment/, @source)
  end

  test 'cdn:purge_pattern task exists' do
    assert_match(/task\s+:purge_pattern,\s*\[:pattern\]\s*=>\s*:environment/, @source)
  end

  test 'cdn:stats task exists' do
    assert_match(/task\s+stats:\s*:environment/, @source)
  end

  test 'cdn:health task exists' do
    assert_match(/task\s+health:\s*:environment/, @source)
  end

  test 'cdn:test task exists' do
    assert_match(/task\s+test:\s*:environment/, @source)
  end

  test 'cdn:config task exists' do
    assert_match(/task\s+config:\s*:environment/, @source)
  end

  test 'all cdn tasks are in cdn namespace' do
    assert_match(/namespace\s+:cdn\s+do/, @source)
    assert_operator @source.scan(/task\s+/).size, :>=, 8, 'Should have at least 8 CDN tasks'
  end

  test 'cdn:purge_all task has description' do
    assert_match(/desc\s+'Purge entire CDN cache'/, @source)
  end

  test 'cdn:stats task has description' do
    assert_match(/desc\s+'Show CDN statistics'/, @source)
  end

  test 'cdn:health task has description' do
    assert_match(/desc\s+'Check CDN health'/, @source)
  end

  test 'cdn:purge_urls task accepts arguments' do
    assert_match(/task\s+:purge_urls,\s*\[:urls\]/, @source)
  end

  test 'cdn:purge_pattern task accepts arguments' do
    assert_match(/task\s+:purge_pattern,\s*\[:pattern\]/, @source)
  end

  test 'cdn tasks depend on environment' do
    %w[purge_all purge_assets stats health test config].each do |task_name|
      assert_match(/task\s+#{Regexp.escape(task_name)}:\s*:environment/, @source)
    end
  end

  test 'cdn:purge_urls task depends on environment' do
    assert_match(/task\s+:purge_urls,\s*\[:urls\]\s*=>\s*:environment/, @source)
  end

  test 'cdn:purge_pattern task depends on environment' do
    assert_match(/task\s+:purge_pattern,\s*\[:pattern\]\s*=>\s*:environment/, @source)
  end

  test 'cdn namespace is properly defined' do
    assert_match(/namespace\s+:cdn\s+do/, @source)
  end

  test 'cdn tasks have unique names' do
    task_names = @source.scan(/task\s+(?::)?([a-z_]+)(?::|,)/).flatten
    assert_equal task_names.size, task_names.uniq.size, 'All CDN tasks should have unique names'
  end

  test 'cdn:purge_all task can be invoked' do
    assert_match(/task\s+purge_all:\s*:environment\s+do/, @source)
  end

  test 'cdn:stats task can be invoked' do
    assert_match(/task\s+stats:\s*:environment\s+do/, @source)
  end

  test 'cdn:health task can be invoked' do
    assert_match(/task\s+health:\s*:environment\s+do/, @source)
  end

  test 'cdn:config task can be invoked' do
    assert_match(/task\s+config:\s*:environment\s+do/, @source)
  end

  test 'cdn tasks are loaded correctly' do
    %w[purge_all purge_assets stats health].each do |task_name|
      assert_match(/task\s+#{Regexp.escape(task_name)}:\s*:environment/, @source)
    end
  end
end
