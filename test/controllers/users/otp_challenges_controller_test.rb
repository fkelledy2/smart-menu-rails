# frozen_string_literal: true

require 'test_helper'

class Users::OtpChallengesControllerTest < ActionDispatch::IntegrationTest
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
  end

  # GET /users/otp_challenge
  test 'show redirects to login when no pending user in session' do
    get users_otp_challenge_path
    assert_redirected_to new_user_session_path
  end

  test 'show renders OTP challenge form when pending user is set' do
    # Simulate the session being set by the sessions controller
    post user_session_path, params: {
      user: { email: @user.email, password: 'password' },
    }
    # Should redirect to OTP challenge
    assert_redirected_to users_otp_challenge_path
    follow_redirect!
    assert_response :success
  end

  # POST /users/otp_challenge
  test 'create with valid TOTP code signs in the user' do
    post user_session_path, params: {
      user: { email: @user.email, password: 'password' },
    }
    assert_redirected_to users_otp_challenge_path

    totp = ROTP::TOTP.new(@secret)
    post users_otp_challenge_path, params: { otp_code: totp.now }
    assert_redirected_to restaurants_path
    assert_not_nil session['warden.user.user.key']
  end

  test 'create with invalid code renders error' do
    post user_session_path, params: {
      user: { email: @user.email, password: 'password' },
    }

    post users_otp_challenge_path, params: { otp_code: '000000' }
    assert_response :unprocessable_entity
  end

  test 'create with locked account shows locked message' do
    @user.update_columns( # rubocop:disable Rails/SkipsModelValidations
      otp_failed_attempts: 5,
      otp_locked_until: 10.minutes.from_now,
    )
    post user_session_path, params: {
      user: { email: @user.email, password: 'password' },
    }

    post users_otp_challenge_path, params: { otp_code: '000000' }
    assert_response :unprocessable_entity
  end

  test 'create with valid backup code signs in' do
    codes = TwoFactor::BackupCodeService.new(@user).generate!
    post user_session_path, params: {
      user: { email: @user.email, password: 'password' },
    }

    post users_otp_challenge_path, params: { otp_code: codes.first }
    assert_redirected_to restaurants_path
  end
end
