require 'test_helper'

class ProviderAccountTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @account = ProviderAccount.new(
      restaurant: @restaurant,
      provider: :stripe,
      provider_account_id: 'acct_test123',
      status: :created,
      environment: 'production',
    )
  end

  test 'valid account saves' do
    assert @account.save
  end

  test 'requires provider' do
    @account.provider = nil
    assert_not @account.valid?
  end

  test 'requires status' do
    @account.status = nil
    assert_not @account.valid?
  end

  test 'requires environment to be production or sandbox' do
    @account.environment = 'staging'
    assert_not @account.valid?
    assert_includes @account.errors[:environment], 'is not included in the list'
  end

  test 'stripe? returns true for stripe provider' do
    @account.provider = :stripe
    assert @account.stripe?
  end

  test 'square? returns true for square provider' do
    @account.provider = :square
    @account.provider_account_id = nil
    assert @account.square?
  end

  test 'provider_account_id required for stripe' do
    @account.provider = :stripe
    @account.provider_account_id = nil
    assert_not @account.valid?
    assert_includes @account.errors[:provider_account_id], "can't be blank"
  end

  test 'provider_account_id not required for square' do
    @account.provider = :square
    @account.provider_account_id = nil
    assert @account.valid?
  end

  test 'token_expired? returns false when token_expires_at is nil' do
    @account.token_expires_at = nil
    assert_not @account.token_expired?
  end

  test 'token_expired? returns true when token_expires_at is in the past' do
    @account.token_expires_at = 1.hour.ago
    assert @account.token_expired?
  end

  test 'token_expired? returns false when token_expires_at is in the future' do
    @account.token_expires_at = 1.hour.from_now
    assert_not @account.token_expired?
  end

  test 'token_expiring_soon? returns false when token_expires_at is nil' do
    @account.token_expires_at = nil
    assert_not @account.token_expiring_soon?
  end

  test 'token_expiring_soon? returns true when expires within default window' do
    @account.token_expires_at = 3.days.from_now
    assert @account.token_expiring_soon?
  end

  test 'token_expiring_soon? returns false when expires after default window' do
    @account.token_expires_at = 30.days.from_now
    assert_not @account.token_expiring_soon?
  end

  test 'sandbox environment is valid' do
    @account.environment = 'sandbox'
    assert @account.valid?
  end

  test 'status enums work' do
    @account.status = :onboarding
    assert @account.onboarding?
    @account.status = :enabled
    assert @account.enabled?
    @account.status = :restricted
    assert @account.restricted?
    @account.status = :disabled
    assert @account.disabled?
  end
end
