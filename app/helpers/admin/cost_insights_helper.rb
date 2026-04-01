# frozen_string_literal: true

module Admin
  module CostInsightsHelper
    ENV_BADGE_CLASSES = {
      'production' => 'success',
      'staging' => 'warning text-dark',
      'development' => 'info text-dark',
      'ephemeral' => 'secondary',
      'unknown' => 'dark',
    }.freeze

    STATUS_BADGE_CLASSES = {
      'draft' => 'secondary',
      'published' => 'success',
      'retired' => 'dark',
    }.freeze

    def env_badge_class(environment)
      ENV_BADGE_CLASSES[environment.to_s] || 'dark'
    end

    def status_badge_class(status)
      STATUS_BADGE_CLASSES[status.to_s] || 'secondary'
    end
  end
end
