# frozen_string_literal: true

# Handles the second-factor OTP step that follows successful password
# validation. Relies on the :otp_user_id key stashed in the session by
# Users::SessionsController#create.
class Users::OtpChallengesController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :load_pending_user

  layout 'devise'

  def show
    # Rendered by app/views/users/otp_challenges/show.html.erb
  end

  def create
    result = TwoFactor::VerificationService.new(@pending_user).verify(params[:otp_code])

    if result.success?
      session.delete(:otp_user_id)

      if params[:trust_device] == '1'
        set_trusted_device_cookie(@pending_user)
      end

      sign_in(:user, @pending_user)
      set_flash_message!(:notice, :signed_in, scope: 'devise.sessions')
      redirect_to stored_location_for(:user) || after_sign_in_path_for(@pending_user)
    elsif result.error == :locked
      @locked_until = result.locked_until
      flash.now[:alert] = t('two_factor.otp_challenge.locked',
        minutes: minutes_until(@locked_until))
      render :show, status: :unprocessable_entity
    else
      flash.now[:alert] = t('two_factor.otp_challenge.invalid_code')
      render :show, status: :unprocessable_entity
    end
  end

  private

  def load_pending_user
    user_id = session[:otp_user_id]

    if user_id.blank?
      redirect_to new_user_session_path, alert: t('two_factor.otp_challenge.session_expired')
      return
    end

    @pending_user = User.find_by(id: user_id)

    unless @pending_user
      session.delete(:otp_user_id)
      redirect_to new_user_session_path, alert: t('two_factor.otp_challenge.session_expired')
    end
  end

  def set_trusted_device_cookie(user)
    fingerprint = SecureRandom.hex(32)
    ttl = 30.days

    # Persist the fingerprint in Redis so it can be revoked server-side.
    redis_key = "trusted_device:#{user.id}:#{fingerprint}"
    $redis&.set(redis_key, '1', ex: ttl.to_i)

    cookies.signed[:trusted_device] = {
      value: fingerprint,
      expires: ttl.from_now,
      httponly: true,
      secure: Rails.env.production?,
    }
  rescue StandardError => e
    Rails.logger.warn("[OtpChallengesController] Failed to set trusted device: #{e.message}")
  end

  def minutes_until(time)
    return 0 if time.nil?

    ((time - Time.current) / 60).ceil
  end
end
