# frozen_string_literal: true

require 'test_helper'

class TwoFactor::VerificationServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @secret = ROTP::Base32.random
    @user.update!(
      otp_secret_key: @secret,
      otp_enabled: true,
      otp_enabled_at: Time.current,
      otp_failed_attempts: 0,
      otp_locked_until: nil,
    )
    @service = TwoFactor::VerificationService.new(@user)
  end

  # TOTP verification
  test 'verifies a valid TOTP code' do
    totp = ROTP::TOTP.new(@secret)
    result = @service.verify(totp.now)
    assert result.success?
    assert_nil result.error
  end

  test 'rejects an invalid TOTP code' do
    result = @service.verify('000000')
    assert_not result.success?
    assert_equal :invalid_code, result.error
  end

  test 'increments otp_failed_attempts on failure' do
    @service.verify('000000')
    @user.reload
    assert_equal 1, @user.otp_failed_attempts
  end

  test 'resets otp_failed_attempts after success' do
    @user.update_columns(otp_failed_attempts: 3) # rubocop:disable Rails/SkipsModelValidations
    totp = ROTP::TOTP.new(@secret)
    @service.verify(totp.now)
    @user.reload
    assert_equal 0, @user.otp_failed_attempts
  end

  # Lockout
  test 'locks account after MAX_ATTEMPTS failed attempts' do
    5.times { @service.verify('000000') }
    @user.reload
    assert @user.otp_locked?
    assert_not_nil @user.otp_locked_until
  end

  test 'returns locked result when account is locked' do
    @user.update_columns( # rubocop:disable Rails/SkipsModelValidations
      otp_failed_attempts: 5,
      otp_locked_until: 10.minutes.from_now,
    )
    service = TwoFactor::VerificationService.new(@user)
    result = service.verify('000000')
    assert_not result.success?
    assert_equal :locked, result.error
    assert_not_nil result.locked_until
  end

  test 'valid TOTP is rejected when account is locked' do
    @user.update_columns( # rubocop:disable Rails/SkipsModelValidations
      otp_locked_until: 5.minutes.from_now,
    )
    totp = ROTP::TOTP.new(@secret)
    service = TwoFactor::VerificationService.new(@user)
    result = service.verify(totp.now)
    assert_not result.success?
    assert_equal :locked, result.error
  end

  test 'lock expires after lockout duration' do
    @user.update_columns( # rubocop:disable Rails/SkipsModelValidations
      otp_failed_attempts: 5,
      otp_locked_until: 1.second.ago,
    )
    service = TwoFactor::VerificationService.new(@user)
    totp = ROTP::TOTP.new(@secret)
    result = service.verify(totp.now)
    assert result.success?
  end

  # Backup code verification
  test 'verifies a valid backup code' do
    codes = TwoFactor::BackupCodeService.new(@user).generate!
    result = @service.verify(codes.first)
    assert result.success?
  end

  test 'consumes backup code on use' do
    codes = TwoFactor::BackupCodeService.new(@user).generate!
    @service.verify(codes.first)
    @user.reload
    assert_equal 9, TwoFactor::BackupCodeService.new(@user).remaining_count
  end

  test 'rejects a backup code a second time' do
    codes = TwoFactor::BackupCodeService.new(@user).generate!
    @service.verify(codes.first)
    result = TwoFactor::VerificationService.new(@user).verify(codes.first)
    assert_not result.success?
  end
end
