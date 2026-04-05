# frozen_string_literal: true

# Manages a user's 2FA security settings:
# - GET  new     — initiate 2FA setup (shows QR code)
# - POST create  — verify the first OTP code to confirm setup
# - GET  show    — current security settings summary
# - DELETE destroy — disable 2FA
# - POST backup_codes — regenerate backup codes
class Users::SecurityController < ApplicationController
  before_action :authenticate_user!
  before_action :check_2fa_feature_flag

  def show
    authorize current_user, :manage_two_factor?, policy_class: UserPolicy
    @backup_code_count = TwoFactor::BackupCodeService.new(current_user).remaining_count
  end

  def new
    authorize current_user, :manage_two_factor?, policy_class: UserPolicy
    result = TwoFactor::SetupService.new(current_user).call
    @qr_svg = result[:qr_svg]
    @provisioning_uri = result[:provisioning_uri]
    # Store the secret in the session — do NOT persist it until verified.
    session[:pending_otp_secret] = result[:secret]
  end

  def create
    authorize current_user, :manage_two_factor?, policy_class: UserPolicy

    secret = session[:pending_otp_secret]

    unless secret.present?
      redirect_to new_users_security_path, alert: t('two_factor.setup.session_expired')
      return
    end

    unless valid_password?(params[:current_password])
      flash.now[:alert] = t('two_factor.setup.invalid_password')
      re_render_new(secret)
      return
    end

    # Verify the entered OTP against the pending secret before activating.
    totp = ROTP::TOTP.new(secret)
    unless totp.verify(params[:otp_code].to_s.strip, drift_behind: 30, drift_ahead: 30)
      flash.now[:alert] = t('two_factor.setup.invalid_otp')
      re_render_new(secret)
      return
    end

    # All good — persist secret and generate backup codes.
    plaintext_codes = TwoFactor::BackupCodeService.new(current_user).generate!
    current_user.update!(
      otp_secret_key: secret,
      otp_enabled: true,
      otp_enabled_at: Time.current,
      otp_failed_attempts: 0,
      otp_locked_until: nil,
    )
    session.delete(:pending_otp_secret)

    @backup_codes = plaintext_codes
    flash.now[:notice] = t('two_factor.setup.success')
    render :backup_codes
  end

  def destroy
    authorize current_user, :manage_two_factor?, policy_class: UserPolicy

    unless valid_password?(params[:current_password])
      redirect_to users_security_path, alert: t('two_factor.disable.invalid_password')
      return
    end

    result = TwoFactor::VerificationService.new(current_user).verify(params[:otp_code])
    unless result.success?
      redirect_to users_security_path, alert: t('two_factor.disable.invalid_otp')
      return
    end

    current_user.update!(
      otp_secret_key: nil,
      otp_enabled: false,
      otp_enabled_at: nil,
      otp_backup_codes: nil,
      otp_failed_attempts: 0,
      otp_locked_until: nil,
    )
    revoke_all_trusted_devices(current_user)

    redirect_to users_security_path, notice: t('two_factor.disable.success')
  end

  def regenerate_backup_codes
    authorize current_user, :manage_two_factor?, policy_class: UserPolicy

    unless valid_password?(params[:current_password])
      redirect_to users_security_path, alert: t('two_factor.backup_codes.invalid_password')
      return
    end

    @backup_codes = TwoFactor::BackupCodeService.new(current_user).generate!
    flash.now[:notice] = t('two_factor.backup_codes.regenerated')
    render :backup_codes
  end

  private

  def check_2fa_feature_flag
    redirect_to root_path unless Flipper.enabled?(:two_factor_auth)
  end

  def valid_password?(password)
    current_user.valid_password?(password.to_s)
  end

  def re_render_new(secret)
    result = TwoFactor::SetupService.new(current_user).call
    @qr_svg = result[:qr_svg]
    @provisioning_uri = result[:provisioning_uri]
    session[:pending_otp_secret] = secret
    render :new, status: :unprocessable_entity
  end

  def revoke_all_trusted_devices(user)
    pattern = "trusted_device:#{user.id}:*"
    $redis&.scan_each(pattern) { |key| $redis.del(key) }
  rescue StandardError => e
    Rails.logger.warn("[SecurityController] Failed to revoke trusted devices: #{e.message}")
  end
end
