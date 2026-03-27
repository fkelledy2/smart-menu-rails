# frozen_string_literal: true

module Jwt
  # Checks whether a validated API token has the required scope for the current action.
  #
  # Usage:
  #   Jwt::ScopeEnforcer.permitted?(token: admin_jwt_token, required_scope: 'menu:read')
  #   # => true / false
  class ScopeEnforcer
    def self.permitted?(token:, required_scope:)
      return false unless token.is_a?(AdminJwtToken)
      return false if required_scope.blank?

      Array(token.scopes).include?(required_scope.to_s)
    end
  end
end
