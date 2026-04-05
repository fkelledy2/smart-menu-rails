# frozen_string_literal: true

module TwoFactor
  # Validates an OTP code or backup code for a user. Handles lockout logic.
  #
  # Returns a result struct with :success, :error, :locked_until.
  class VerificationService
    MAX_ATTEMPTS = 5
    LOCKOUT_DURATION = 15.minutes
    DRIFT_SECONDS = 30 # allow ±1 TOTP step

    Result = Struct.new(:success, :error, :locked_until, keyword_init: true) do
      def success? = success
    end

    def initialize(user)
      @user = user
    end

    # Verifies either a TOTP code or a backup code.
    # @param code [String] the OTP or backup code entered by the user
    # @return [Result]
    def verify(code)
      return locked_result if currently_locked?

      code = code.to_s.strip

      if valid_totp?(code) || valid_backup_code?(code)
        reset_failed_attempts
        Result.new(success: true, error: nil, locked_until: nil)
      else
        handle_failed_attempt
      end
    end

    private

    attr_reader :user

    def currently_locked?
      user.otp_locked_until.present? && user.otp_locked_until > Time.current
    end

    def locked_result
      Result.new(
        success: false,
        error: :locked,
        locked_until: user.otp_locked_until,
      )
    end

    def valid_totp?(code)
      return false if user.otp_secret_key.blank?

      totp = ROTP::TOTP.new(user.otp_secret_key)
      totp.verify(code, drift_behind: DRIFT_SECONDS, drift_ahead: DRIFT_SECONDS).present?
    end

    def valid_backup_code?(code)
      BackupCodeService.new(user).consume!(code)
    end

    def reset_failed_attempts
      user.update_columns( # rubocop:disable Rails/SkipsModelValidations
        otp_failed_attempts: 0,
        otp_locked_until: nil,
      )
    end

    def handle_failed_attempt
      attempts = (user.otp_failed_attempts || 0) + 1
      locked_until = attempts >= MAX_ATTEMPTS ? LOCKOUT_DURATION.from_now : nil

      user.update_columns( # rubocop:disable Rails/SkipsModelValidations
        otp_failed_attempts: attempts,
        otp_locked_until: locked_until,
      )

      if locked_until
        Result.new(success: false, error: :locked, locked_until: locked_until)
      else
        Result.new(
          success: false,
          error: :invalid_code,
          locked_until: nil,
        )
      end
    end
  end
end
