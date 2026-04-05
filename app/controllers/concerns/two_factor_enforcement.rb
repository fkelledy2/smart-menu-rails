# frozen_string_literal: true

# Enforces 2FA completion for admin-role employees when the
# two_factor_enforcement Flipper flag is enabled.
#
# Include in ApplicationController to apply globally.
module TwoFactorEnforcement
  extend ActiveSupport::Concern

  EXEMPT_CONTROLLERS = %w[
    users/sessions
    users/otp_challenges
    users/security
    devise/sessions
    devise/passwords
    devise/registrations
    devise/unlocks
  ].freeze

  included do
    before_action :enforce_two_factor_for_admins
  end

  private

  def enforce_two_factor_for_admins
    return unless current_user.present?
    return unless Flipper.enabled?(:two_factor_enforcement)
    return if exempt_from_enforcement?
    return unless current_user.admin_employee_anywhere?
    return if current_user.two_factor_enabled?

    redirect_to new_users_security_path,
      alert: I18n.t('two_factor.enforcement.required')
  end

  def exempt_from_enforcement?
    EXEMPT_CONTROLLERS.include?(params[:controller])
  end
end
