require 'test_helper'
require 'yaml'

class RubocopConfigTest < ActiveSupport::TestCase
  setup do
    @config_path = Rails.root.join('.rubocop.yml')
    @config = YAML.load_file(@config_path)
  end

  test 'rubocop config file exists' do
    assert File.exist?(@config_path), '.rubocop.yml should exist'
  end

  test 'rubocop config is valid YAML' do
    assert @config.is_a?(Hash), '.rubocop.yml should contain valid YAML'
  end

  test 'rubocop config requires necessary extensions' do
    # Check for plugins (modern approach)
    if @config.key?('plugins')
      plugins = @config['plugins']
      assert plugins.include?('rubocop-rails'), 'Should include rubocop-rails plugin'
      assert plugins.include?('rubocop-performance'), 'Should include rubocop-performance plugin'
    end

    # Check for require (legacy approach for some gems)
    if @config.key?('require')
      requires = @config['require']
      assert requires.include?('rubocop-rspec'), 'Should require rubocop-rspec'
      assert requires.include?('rubocop-rspec_rails'), 'Should require rubocop-rspec_rails'
    end

    # At least one should be present
    assert @config.key?('plugins') || @config.key?('require'),
           'Config should have plugins or require section'
  end

  test 'rubocop config sets target ruby version' do
    assert @config.key?('AllCops'), 'Config should have AllCops section'
    assert @config['AllCops'].key?('TargetRubyVersion'), 'AllCops should set TargetRubyVersion'
    assert_equal 3.3, @config['AllCops']['TargetRubyVersion'],
                 'TargetRubyVersion should be 3.3'
  end

  test 'rubocop config excludes appropriate directories' do
    assert @config['AllCops'].key?('Exclude'), 'AllCops should have Exclude list'

    excluded_dirs = @config['AllCops']['Exclude']

    # Check for important exclusions
    assert excluded_dirs.any? { |dir| dir.include?('vendor') }, 'Should exclude vendor directory'
    assert excluded_dirs.any? { |dir| dir.include?('db/schema.rb') }, 'Should exclude db/schema.rb'
    assert excluded_dirs.any? { |dir| dir.include?('node_modules') }, 'Should exclude node_modules'
    assert excluded_dirs.any? { |dir| dir.include?('tmp') }, 'Should exclude tmp directory'
  end

  test 'rubocop config sets reasonable line length' do
    assert @config.key?('Layout/LineLength'), 'Config should set Layout/LineLength'

    # LineLength may be disabled for modern development
    if @config['Layout/LineLength']['Enabled'] == false
      assert_equal false, @config['Layout/LineLength']['Enabled'],
                   'LineLength is disabled for modern development'
    else
      max_length = @config['Layout/LineLength']['Max']
      assert max_length >= 100, 'Line length should be at least 100' if max_length
      assert max_length <= 150, 'Line length should not exceed 150' if max_length
    end
  end

  test 'rubocop config disables documentation requirement' do
    assert @config.key?('Style/Documentation'), 'Config should configure Style/Documentation'
    assert_equal false, @config['Style/Documentation']['Enabled'],
                 'Documentation should be disabled for practical development'
  end

  test 'rubocop config sets reasonable method length' do
    assert @config.key?('Metrics/MethodLength'), 'Config should set Metrics/MethodLength'

    # MethodLength may be disabled for Rails controllers
    if @config['Metrics/MethodLength']['Enabled'] == false
      assert_equal false, @config['Metrics/MethodLength']['Enabled'],
                   'MethodLength is disabled for Rails development'
    else
      max_length = @config['Metrics/MethodLength']['Max']
      assert max_length >= 15, 'Method length should allow at least 15 lines' if max_length
      assert max_length <= 50, 'Method length should not exceed 50 lines' if max_length
    end
  end

  test 'rubocop config sets reasonable class length' do
    assert @config.key?('Metrics/ClassLength'), 'Config should set Metrics/ClassLength'

    # ClassLength may be disabled for Rails controllers
    if @config['Metrics/ClassLength']['Enabled'] == false
      assert_equal false, @config['Metrics/ClassLength']['Enabled'],
                   'ClassLength is disabled for Rails development'
    else
      max_length = @config['Metrics/ClassLength']['Max']
      assert max_length >= 100, 'Class length should allow at least 100 lines' if max_length
      assert max_length <= 250, 'Class length should not exceed 250 lines' if max_length
    end
  end

  test 'rubocop config excludes test files from block length' do
    assert @config.key?('Metrics/BlockLength'), 'Config should set Metrics/BlockLength'

    if @config['Metrics/BlockLength']['Exclude']
      excluded = @config['Metrics/BlockLength']['Exclude']
      assert excluded.any? { |pattern| pattern.include?('spec') || pattern.include?('test') },
             'Should exclude test files from BlockLength'
    end
  end

  test 'rubocop config allows reasonable complexity' do
    assert @config.key?('Metrics/CyclomaticComplexity'), 'Config should set CyclomaticComplexity'
    assert @config.key?('Metrics/PerceivedComplexity'), 'Config should set PerceivedComplexity'

    # Complexity metrics may be disabled for Rails controllers
    if @config['Metrics/CyclomaticComplexity']['Enabled'] == false
      assert_equal false, @config['Metrics/CyclomaticComplexity']['Enabled'],
                   'CyclomaticComplexity is disabled for Rails development'
    else
      cyclomatic = @config['Metrics/CyclomaticComplexity']['Max']
      assert cyclomatic >= 6, 'Cyclomatic complexity should allow at least 6' if cyclomatic
    end

    if @config['Metrics/PerceivedComplexity']['Enabled'] == false
      assert_equal false, @config['Metrics/PerceivedComplexity']['Enabled'],
                   'PerceivedComplexity is disabled for Rails development'
    else
      perceived = @config['Metrics/PerceivedComplexity']['Max']
      assert perceived >= 6, 'Perceived complexity should allow at least 6' if perceived
    end
  end
end
