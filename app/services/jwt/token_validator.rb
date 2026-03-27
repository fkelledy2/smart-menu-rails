# frozen_string_literal: true

module Jwt
  # Validates an incoming API JWT and returns the associated AdminJwtToken record.
  #
  # Checks in order:
  #   1. JWT signature and expiry (via the JWT gem)
  #   2. The token must not be revoked
  #   3. The `restaurant_id` claim must match the request context
  #
  # Usage:
  #   result = Jwt::TokenValidator.call(raw_jwt: bearer_token, restaurant_id: params[:restaurant_id])
  #   result.valid?   # => true / false
  #   result.token    # => AdminJwtToken instance (when valid)
  #   result.error    # => :expired | :revoked | :invalid | :not_found | :restaurant_mismatch
  class TokenValidator
    Result = Struct.new(:valid, :token, :payload, :error, keyword_init: true) do
      def valid? = valid
    end

    def self.call(**)
      new(**).call
    end

    def initialize(raw_jwt:, restaurant_id: nil)
      @raw_jwt       = raw_jwt
      @restaurant_id = restaurant_id&.to_i
    end

    def call
      return Result.new(valid: false, error: :invalid) if @raw_jwt.blank?

      payload = decode_jwt
      return Result.new(valid: false, error: :expired) if payload == :expired
      return Result.new(valid: false, error: :invalid) unless payload

      token = find_token(payload)
      return Result.new(valid: false, error: :not_found) unless token

      return Result.new(valid: false, error: :revoked) if token.revoked?
      return Result.new(valid: false, error: :expired) if token.expired?

      if @restaurant_id && payload['restaurant_id'].to_i != @restaurant_id
        return Result.new(valid: false, error: :restaurant_mismatch)
      end

      Result.new(valid: true, token: token, payload: payload)
    end

    private

    def decode_jwt
      decoded = JWT.decode(@raw_jwt, secret_key, true, algorithm: 'HS256')
      ActiveSupport::HashWithIndifferentAccess.new(decoded[0])
    rescue JWT::ExpiredSignature
      :expired
    rescue JWT::DecodeError
      nil
    end

    def find_token(payload)
      token_hash = Digest::SHA256.hexdigest(@raw_jwt)
      AdminJwtToken.find_by(token_hash: token_hash)
    end

    def secret_key
      ENV.fetch('JWT_SECRET_KEY', Rails.application.secret_key_base)
    end
  end
end
