# frozen_string_literal: true

module Admin
  module CostInsightsHelper
    ENV_BADGE_VARIANTS = {
      'production' => 'success',
      'staging' => 'warning',
      'development' => 'info',
      'ephemeral' => 'secondary',
      'unknown' => 'dark',
    }.freeze

    STATUS_BADGE_VARIANTS = {
      'draft' => 'secondary',
      'published' => 'success',
      'retired' => 'dark',
    }.freeze

    def env_badge_class(environment)
      ENV_BADGE_VARIANTS[environment.to_s] || 'dark'
    end

    def status_badge_class(status)
      STATUS_BADGE_VARIANTS[status.to_s] || 'secondary'
    end
  end
end
