# frozen_string_literal: true

module Heroku
  # Classifies a Heroku app into an environment category.
  # Primary: pipeline stage → production/staging/development/ephemeral
  # Fallback: app name pattern matching
  class EnvironmentClassifier
    STAGE_MAP = {
      'production' => 'production',
      'staging' => 'staging',
      'development' => 'development',
      'review' => 'ephemeral',
    }.freeze

    PATTERNS = [
      [/\bpr-\d+\b/i, 'ephemeral'],
      [/review/i,           'ephemeral'],
      [/staging/i,          'staging'],
      [/stage/i,            'staging'],
      [/dev(elopment)?\b/i, 'development'],
      [/production\b/i,     'production'],
      [/-prod\b/i,          'production'],
    ].freeze

    # @param pipeline_stage [String, nil]
    # @param app_name [String, nil]
    # @return [String] one of: production, staging, development, ephemeral, unknown
    def self.classify(pipeline_stage: nil, app_name: nil)
      env = STAGE_MAP[pipeline_stage.to_s.downcase]
      return env if env

      PATTERNS.each do |pattern, classification|
        return classification if app_name.to_s.match?(pattern)
      end

      'unknown'
    end
  end
end
