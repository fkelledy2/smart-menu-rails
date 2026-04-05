# frozen_string_literal: true

require 'test_helper'

class TwoFactor::BackupCodeServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @user.update_columns(otp_backup_codes: nil) # rubocop:disable Rails/SkipsModelValidations
    @service = TwoFactor::BackupCodeService.new(@user)
  end

  # generate!
  test 'generates 10 backup codes' do
    codes = @service.generate!
    assert_equal 10, codes.length
  end

  test 'generated codes are alphanumeric and 10 characters' do
    codes = @service.generate!
    codes.each do |code|
      assert_match(/\A[a-zA-Z0-9]{10}\z/, code)
    end
  end

  test 'codes are stored as bcrypt hashes in otp_backup_codes' do
    codes = @service.generate!
    @user.reload
    stored = JSON.parse(@user.otp_backup_codes)
    assert_equal 10, stored.length
    # Stored values should not be the plaintext codes
    codes.each { |c| assert_not_includes stored, c }
    # Each stored value should be a valid bcrypt hash
    stored.each { |h| assert_match(/\A\$2a\$/, h) }
  end

  test 'generate! overwrites previous backup codes' do
    first_codes = @service.generate!
    second_codes = @service.generate!
    assert_not_equal first_codes, second_codes
    @user.reload
    # Previous codes should be invalidated
    refute @service.consume!(first_codes.first)
  end

  # consume!
  test 'consume! returns true for a valid code' do
    codes = @service.generate!
    assert @service.consume!(codes.first)
  end

  test 'consume! removes the consumed code' do
    codes = @service.generate!
    @service.consume!(codes.first)
    @user.reload
    remaining = JSON.parse(@user.otp_backup_codes)
    assert_equal 9, remaining.length
  end

  test 'consume! returns false for an already-used code' do
    codes = @service.generate!
    @service.consume!(codes.first)
    assert_not @service.consume!(codes.first)
  end

  test 'consume! returns false for an invalid code' do
    @service.generate!
    assert_not @service.consume!('invalid000')
  end

  test 'consume! returns false when no codes exist' do
    assert_not @service.consume!('anything00')
  end

  # remaining_count
  test 'remaining_count returns 10 after generate!' do
    @service.generate!
    assert_equal 10, @service.remaining_count
  end

  test 'remaining_count decrements after consume!' do
    codes = @service.generate!
    @service.consume!(codes.first)
    @user.reload
    assert_equal 9, TwoFactor::BackupCodeService.new(@user).remaining_count
  end

  test 'remaining_count returns 0 when no backup codes' do
    assert_equal 0, @service.remaining_count
  end
end
