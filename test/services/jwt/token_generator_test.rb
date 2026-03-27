# frozen_string_literal: true

require 'test_helper'

module Jwt
  class TokenGeneratorTest < ActiveSupport::TestCase
    def setup
      @admin_user = users(:super_admin)
      @restaurant = restaurants(:one)
    end

    test 'generates a token record and returns raw JWT' do
      result = Jwt::TokenGenerator.call(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: 'Integration Token',
        scopes: ['menu:read', 'orders:read'],
        expires_in: 30.days,
      )

      assert result.success?, "Expected success but got error: #{result.error}"
      assert result.raw_jwt.present?
      assert_instance_of AdminJwtToken, result.token
      assert_equal 'Integration Token', result.token.name
      assert_equal ['menu:read', 'orders:read'], result.token.scopes
    end

    test 'stores token as SHA-256 hash, not raw JWT' do
      result = Jwt::TokenGenerator.call(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: 'Hash Test',
        scopes: ['menu:read'],
      )

      assert result.success?
      expected_hash = Digest::SHA256.hexdigest(result.raw_jwt)
      assert_equal expected_hash, result.token.token_hash
    end

    test 'raw JWT contains expected claims' do
      result = Jwt::TokenGenerator.call(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: 'Claims Test',
        scopes: ['analytics:read'],
        expires_in: 60.days,
      )

      assert result.success?

      secret = ENV.fetch('JWT_SECRET_KEY', Rails.application.secret_key_base)
      payload = JWT.decode(result.raw_jwt, secret, true, algorithm: 'HS256')[0]

      assert_equal 'mellow.menu', payload['iss']
      assert_equal "restaurant:#{@restaurant.id}", payload['sub']
      assert_equal 'mellow-api', payload['aud']
      assert_equal @restaurant.id, payload['restaurant_id']
      assert_equal @admin_user.id, payload['admin_user_id']
      assert_equal ['analytics:read'], payload['scopes']
    end

    test 'returns failure when name is blank' do
      result = Jwt::TokenGenerator.call(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: '',
        scopes: ['menu:read'],
      )

      assert_not result.success?
      assert result.error.present?
    end

    test 'returns failure when scopes are invalid' do
      result = Jwt::TokenGenerator.call(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: 'Bad Scopes',
        scopes: ['invalid:scope'],
      )

      assert_not result.success?
    end

    test 'expires_at is set according to expires_in' do
      freeze_time do
        result = Jwt::TokenGenerator.call(
          admin_user: @admin_user,
          restaurant: @restaurant,
          name: 'Expiry Test',
          scopes: ['menu:read'],
          expires_in: 90.days,
        )

        assert result.success?
        assert_in_delta 90.days.from_now.to_i, result.token.expires_at.to_i, 2
      end
    end
  end
end
