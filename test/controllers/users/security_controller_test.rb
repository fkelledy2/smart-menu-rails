# frozen_string_literal: true

require 'test_helper'

class Users::SecurityControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    Flipper.enable(:two_factor_auth)
  end

  def teardown
    Flipper.disable(:two_factor_auth)
  end

  # GET /users/security
  test 'show requires authentication' do
    get users_security_path
    assert_redirected_to new_user_session_path
  end

  test 'show renders for authenticated user' do
    sign_in @user
    get users_security_path
    assert_response :success
  end

  # GET /users/security/new
  test 'new requires authentication' do
    get new_users_security_path
    assert_redirected_to new_user_session_path
  end

  test 'new renders QR code setup page' do
    sign_in @user
    get new_users_security_path
    assert_response :success
    assert_not_nil session[:pending_otp_secret]
  end

  # POST /users/security (create — verify and activate 2FA)
  test 'create fails with invalid password' do
    sign_in @user
    get new_users_security_path
    secret = session[:pending_otp_secret]
    totp = ROTP::TOTP.new(secret)

    post users_security_path, params: {
      current_password: 'wrongpassword',
      otp_code: totp.now,
    }
    assert_response :unprocessable_entity
    assert_not @user.reload.otp_enabled?
  end

  test 'create fails with invalid OTP code' do
    sign_in @user
    get new_users_security_path

    post users_security_path, params: {
      current_password: 'password',
      otp_code: '000000',
    }
    assert_response :unprocessable_entity
    assert_not @user.reload.otp_enabled?
  end

  test 'create activates 2FA with valid credentials' do
    sign_in @user
    get new_users_security_path
    secret = session[:pending_otp_secret]
    totp = ROTP::TOTP.new(secret)

    post users_security_path, params: {
      current_password: 'password',
      otp_code: totp.now,
    }
    assert_response :success
    @user.reload
    assert @user.otp_enabled?
    assert_not_nil @user.otp_secret_key
    assert_not_nil @user.otp_enabled_at
  end

  # DELETE /users/security (disable 2FA)
  test 'destroy disables 2FA with valid credentials' do
    secret = ROTP::Base32.random
    @user.update!(
      otp_secret_key: secret,
      otp_enabled: true,
      otp_enabled_at: Time.current,
    )
    TwoFactor::BackupCodeService.new(@user).generate!
    sign_in @user

    totp = ROTP::TOTP.new(secret)
    delete users_security_path, params: {
      current_password: 'password',
      otp_code: totp.now,
    }
    assert_redirected_to users_security_path
    @user.reload
    assert_not @user.otp_enabled?
    assert_nil @user.otp_secret_key
  end

  test 'destroy fails with wrong password' do
    secret = ROTP::Base32.random
    @user.update!(otp_secret_key: secret, otp_enabled: true, otp_enabled_at: Time.current)
    sign_in @user

    delete users_security_path, params: {
      current_password: 'wrongpassword',
      otp_code: ROTP::TOTP.new(secret).now,
    }
    assert_redirected_to users_security_path
    assert @user.reload.otp_enabled?
  end

  # POST /users/security/regenerate_backup_codes
  test 'regenerate_backup_codes generates new codes' do
    secret = ROTP::Base32.random
    @user.update!(otp_secret_key: secret, otp_enabled: true, otp_enabled_at: Time.current)
    TwoFactor::BackupCodeService.new(@user).generate!
    old_codes_json = @user.reload.otp_backup_codes
    sign_in @user

    post regenerate_backup_codes_users_security_path, params: { current_password: 'password' }
    assert_response :success
    @user.reload
    assert_not_equal old_codes_json, @user.otp_backup_codes
  end

  test 'security settings redirect to root when flag disabled' do
    Flipper.disable(:two_factor_auth)
    sign_in @user
    get users_security_path
    assert_redirected_to root_path
  end
end
