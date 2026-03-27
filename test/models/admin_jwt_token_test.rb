# frozen_string_literal: true

require 'test_helper'

class AdminJwtTokenTest < ActiveSupport::TestCase
  def setup
    @admin_user  = users(:super_admin)
    @restaurant  = restaurants(:one)
    @valid_attrs = {
      admin_user: @admin_user,
      restaurant: @restaurant,
      name: 'Test Token',
      token_hash: 'a' * 64,
      scopes: ['menu:read'],
      expires_at: 30.days.from_now,
      rate_limit_per_minute: 60,
      rate_limit_per_hour: 1000,
    }
  end

  # --- Associations ---

  test 'belongs to admin_user' do
    token = AdminJwtToken.new(@valid_attrs)
    assert_equal @admin_user, token.admin_user
  end

  test 'belongs to restaurant' do
    token = AdminJwtToken.new(@valid_attrs)
    assert_equal @restaurant, token.restaurant
  end

  test 'has many usage_logs' do
    token = admin_jwt_tokens(:active_token)
    assert_respond_to token, :usage_logs
    assert token.usage_logs.count >= 2
  end

  # --- Validations ---

  test 'valid with all required attributes' do
    token = AdminJwtToken.new(@valid_attrs)
    assert token.valid?
  end

  test 'invalid without name' do
    token = AdminJwtToken.new(@valid_attrs.merge(name: nil))
    assert token.invalid?
    assert_includes token.errors[:name], "can't be blank"
  end

  test 'invalid without token_hash' do
    token = AdminJwtToken.new(@valid_attrs.merge(token_hash: nil))
    assert token.invalid?
  end

  test 'invalid without scopes' do
    token = AdminJwtToken.new(@valid_attrs.merge(scopes: nil))
    assert token.invalid?
  end

  test 'invalid without expires_at' do
    token = AdminJwtToken.new(@valid_attrs.merge(expires_at: nil))
    assert token.invalid?
  end

  test 'invalid when expires_at is in the past on create' do
    token = AdminJwtToken.new(@valid_attrs.merge(expires_at: 1.day.ago))
    assert token.invalid?
    assert_includes token.errors[:expires_at], 'must be in the future'
  end

  test 'invalid with unknown scope value' do
    token = AdminJwtToken.new(@valid_attrs.merge(scopes: ['menu:read', 'unknown:scope']))
    assert token.invalid?
    assert(token.errors[:scopes].any? { |e| e.include?('invalid values') })
  end

  test 'valid with all defined scopes' do
    token = AdminJwtToken.new(@valid_attrs.merge(scopes: AdminJwtToken::VALID_SCOPES))
    assert token.valid?
  end

  test 'invalid with rate_limit_per_minute of zero' do
    token = AdminJwtToken.new(@valid_attrs.merge(rate_limit_per_minute: 0))
    assert token.invalid?
  end

  test 'token_hash must be unique' do
    existing = admin_jwt_tokens(:active_token)
    dup = AdminJwtToken.new(@valid_attrs.merge(token_hash: existing.token_hash))
    assert dup.invalid?
    assert_includes dup.errors[:token_hash], 'has already been taken'
  end

  # --- Status methods ---

  test 'active? returns true for non-revoked, non-expired token' do
    token = admin_jwt_tokens(:active_token)
    assert token.active?
  end

  test 'active? returns false when revoked' do
    token = admin_jwt_tokens(:revoked_token)
    assert_not token.active?
  end

  test 'active? returns false when expired' do
    token = admin_jwt_tokens(:expired_token)
    assert_not token.active?
  end

  test 'revoked? returns true when revoked_at is set' do
    token = admin_jwt_tokens(:revoked_token)
    assert token.revoked?
  end

  test 'expired? returns true when expires_at is in the past and not revoked' do
    token = admin_jwt_tokens(:expired_token)
    assert token.expired?
  end

  test 'status returns :active for an active token' do
    assert_equal :active, admin_jwt_tokens(:active_token).status
  end

  test 'status returns :revoked for a revoked token' do
    assert_equal :revoked, admin_jwt_tokens(:revoked_token).status
  end

  test 'status returns :expired for an expired token' do
    assert_equal :expired, admin_jwt_tokens(:expired_token).status
  end

  # --- Scopes ---

  test 'active scope excludes revoked tokens' do
    active_ids = AdminJwtToken.active.pluck(:id)
    assert_not_includes active_ids, admin_jwt_tokens(:revoked_token).id
  end

  test 'active scope excludes expired tokens' do
    active_ids = AdminJwtToken.active.pluck(:id)
    assert_not_includes active_ids, admin_jwt_tokens(:expired_token).id
  end

  test 'revoked scope returns only revoked tokens' do
    revoked = AdminJwtToken.revoked
    assert revoked.all?(&:revoked?)
  end

  test 'expiring_soon scope returns tokens expiring within N days' do
    token = admin_jwt_tokens(:active_token)
    token.update_column(:expires_at, 3.days.from_now)
    assert_includes AdminJwtToken.expiring_soon(7), token
    assert_not_includes AdminJwtToken.expiring_soon(1), token
  end

  # --- #revoke! ---

  test 'revoke! sets revoked_at to current time' do
    token = admin_jwt_tokens(:active_token)
    freeze_time do
      token.revoke!
      assert_in_delta Time.current.to_i, token.reload.revoked_at.to_i, 2
    end
  end

  # --- #record_usage! ---

  test 'record_usage! creates a usage log and increments usage_count' do
    token  = admin_jwt_tokens(:active_token)
    before = token.usage_count

    assert_difference -> { JwtTokenUsageLog.count }, 1 do
      token.record_usage!(
        endpoint: '/api/v1/test',
        http_method: 'GET',
        ip_address: '1.2.3.4',
        response_status: 200,
      )
    end

    assert_equal before + 1, token.reload.usage_count
    assert_not_nil token.last_used_at
  end
end
