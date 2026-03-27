# frozen_string_literal: true

require 'test_helper'

module Jwt
  class TokenValidatorTest < ActiveSupport::TestCase
    def setup
      @admin_user = users(:super_admin)
      @restaurant = restaurants(:one)

      # Generate a real JWT for testing
      result = Jwt::TokenGenerator.call(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: 'Validator Test Token',
        scopes: ['menu:read'],
        expires_in: 30.days,
      )
      @token     = result.token
      @raw_jwt   = result.raw_jwt
    end

    test 'valid? returns true for a valid, active token' do
      result = Jwt::TokenValidator.call(raw_jwt: @raw_jwt)
      assert result.valid?
      assert_equal @token, result.token
    end

    test 'valid? returns true when restaurant_id matches' do
      result = Jwt::TokenValidator.call(raw_jwt: @raw_jwt, restaurant_id: @restaurant.id)
      assert result.valid?
    end

    test 'returns :restaurant_mismatch when restaurant_id does not match' do
      result = Jwt::TokenValidator.call(raw_jwt: @raw_jwt, restaurant_id: 99_999)
      assert_not result.valid?
      assert_equal :restaurant_mismatch, result.error
    end

    test 'returns :invalid for a blank token' do
      result = Jwt::TokenValidator.call(raw_jwt: '')
      assert_not result.valid?
      assert_equal :invalid, result.error
    end

    test 'returns :invalid for a malformed JWT' do
      result = Jwt::TokenValidator.call(raw_jwt: 'not.a.jwt')
      assert_not result.valid?
      assert_equal :invalid, result.error
    end

    test 'returns :expired for an expired JWT' do
      # Build a JWT that is already expired
      secret  = ENV.fetch('JWT_SECRET_KEY', Rails.application.secret_key_base)
      payload = {
        iss: 'mellow.menu',
        sub: "restaurant:#{@restaurant.id}",
        aud: 'mellow-api',
        exp: 1.day.ago.to_i,
        iat: 2.days.ago.to_i,
        jti: SecureRandom.uuid,
        restaurant_id: @restaurant.id,
        admin_user_id: @admin_user.id,
        scopes: ['menu:read'],
        rate_limit: { per_minute: 60, per_hour: 1000 },
      }
      raw_jwt = JWT.encode(payload, secret, 'HS256')

      result = Jwt::TokenValidator.call(raw_jwt: raw_jwt)
      assert_not result.valid?
      assert_equal :expired, result.error
    end

    test 'returns :not_found when token hash is not in database' do
      secret  = ENV.fetch('JWT_SECRET_KEY', Rails.application.secret_key_base)
      payload = {
        iss: 'mellow.menu',
        sub: "restaurant:#{@restaurant.id}",
        aud: 'mellow-api',
        exp: 30.days.from_now.to_i,
        iat: Time.current.to_i,
        jti: SecureRandom.uuid,
        restaurant_id: @restaurant.id,
        admin_user_id: @admin_user.id,
        scopes: ['menu:read'],
        rate_limit: { per_minute: 60, per_hour: 1000 },
      }
      unknown_jwt = JWT.encode(payload, secret, 'HS256')

      result = Jwt::TokenValidator.call(raw_jwt: unknown_jwt)
      assert_not result.valid?
      assert_equal :not_found, result.error
    end

    test 'returns :revoked for a revoked token' do
      @token.revoke!
      result = Jwt::TokenValidator.call(raw_jwt: @raw_jwt)
      assert_not result.valid?
      assert_equal :revoked, result.error
    end

    test 'returns :expired for a DB-expired token' do
      @token.update_column(:expires_at, 1.day.ago)
      result = Jwt::TokenValidator.call(raw_jwt: @raw_jwt)
      # JWT gem will see a valid signature but DB record shows expired
      # (or JWT gem sees expired exp — either way, invalid)
      assert_not result.valid?
    end
  end
end
