# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # After Devise validates email + password, check whether the user has 2FA
  # enabled. If so, stash the user_id in the session and redirect to the OTP
  # challenge instead of signing them in immediately.
  def create
    self.resource = warden.authenticate!(auth_options)

    if resource.two_factor_enabled? && !trusted_device?(resource)
      # Do NOT sign in yet — store the pending user in session and challenge.
      session[:otp_user_id] = resource.id
      store_location_for(resource, after_sign_in_path_for(resource))
      redirect_to users_otp_challenge_path
    else
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end

  private

  # Checks whether the current device has a valid trusted-device cookie in Redis.
  def trusted_device?(user)
    fingerprint = cookies.signed[:trusted_device]
    return false if fingerprint.blank?

    redis_key = "trusted_device:#{user.id}:#{fingerprint}"
    $redis&.exists?(redis_key)
  rescue StandardError
    false
  end
end
