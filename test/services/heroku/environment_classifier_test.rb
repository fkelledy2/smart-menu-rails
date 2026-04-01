# frozen_string_literal: true

require 'test_helper'

class Heroku::EnvironmentClassifierTest < ActiveSupport::TestCase
  test 'classifies production pipeline stage' do
    assert_equal 'production', Heroku::EnvironmentClassifier.classify(pipeline_stage: 'production')
  end

  test 'classifies staging pipeline stage' do
    assert_equal 'staging', Heroku::EnvironmentClassifier.classify(pipeline_stage: 'staging')
  end

  test 'classifies review pipeline stage as ephemeral' do
    assert_equal 'ephemeral', Heroku::EnvironmentClassifier.classify(pipeline_stage: 'review')
  end

  test 'classifies development pipeline stage' do
    assert_equal 'development', Heroku::EnvironmentClassifier.classify(pipeline_stage: 'development')
  end

  test 'falls back to app name matching for staging pattern' do
    assert_equal 'staging', Heroku::EnvironmentClassifier.classify(
      pipeline_stage: nil,
      app_name: 'smart-menu-web-staging',
    )
  end

  test 'falls back to app name matching for production pattern' do
    assert_equal 'production', Heroku::EnvironmentClassifier.classify(
      pipeline_stage: nil,
      app_name: 'smart-menu-production',
    )
  end

  test 'falls back to app name matching for PR pattern' do
    assert_equal 'ephemeral', Heroku::EnvironmentClassifier.classify(
      pipeline_stage: nil,
      app_name: 'smart-menu-pr-123',
    )
  end

  test 'returns unknown for unrecognized patterns' do
    assert_equal 'unknown', Heroku::EnvironmentClassifier.classify(
      pipeline_stage: nil,
      app_name: 'random-app-name',
    )
  end

  test 'pipeline stage takes precedence over app name' do
    assert_equal 'production', Heroku::EnvironmentClassifier.classify(
      pipeline_stage: 'production',
      app_name: 'smart-menu-staging',
    )
  end
end
