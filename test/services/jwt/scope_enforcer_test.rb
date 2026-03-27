# frozen_string_literal: true

require 'test_helper'

module Jwt
  class ScopeEnforcerTest < ActiveSupport::TestCase
    def setup
      @admin_user = users(:super_admin)
      @restaurant = restaurants(:one)
    end

    def build_token(scopes:)
      AdminJwtToken.new(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: 'Test',
        token_hash: SecureRandom.hex(32),
        scopes: scopes,
        expires_at: 30.days.from_now,
        rate_limit_per_minute: 60,
        rate_limit_per_hour: 1000,
      )
    end

    test 'returns true when token has the required scope' do
      token = build_token(scopes: ['menu:read', 'orders:read'])
      assert Jwt::ScopeEnforcer.permitted?(token: token, required_scope: 'menu:read')
    end

    test 'returns false when token does not have the required scope' do
      token = build_token(scopes: ['analytics:read'])
      assert_not Jwt::ScopeEnforcer.permitted?(token: token, required_scope: 'menu:read')
    end

    test 'returns false for empty scopes' do
      token = build_token(scopes: [])
      assert_not Jwt::ScopeEnforcer.permitted?(token: token, required_scope: 'menu:read')
    end

    test 'returns false when token is nil' do
      assert_not Jwt::ScopeEnforcer.permitted?(token: nil, required_scope: 'menu:read')
    end

    test 'returns false when required_scope is blank' do
      token = build_token(scopes: ['menu:read'])
      assert_not Jwt::ScopeEnforcer.permitted?(token: token, required_scope: '')
    end

    test 'returns false when record is not an AdminJwtToken' do
      assert_not Jwt::ScopeEnforcer.permitted?(token: 'not_a_token', required_scope: 'menu:read')
    end
  end
end
