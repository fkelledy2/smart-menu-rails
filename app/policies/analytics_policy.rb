# frozen_string_literal: true

class AnalyticsPolicy < ApplicationPolicy
  def track?
    # Allow authenticated users to track analytics events
    user.present?
  end

  def track_anonymous?
    # Allow anonymous analytics tracking (no authentication required)
    true
  end
end
