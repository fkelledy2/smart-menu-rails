# frozen_string_literal: true

module Jwt
  # Generates a signed JWT for API access and persists the token record.
  #
  # Algorithm: HS256 (consistent with the existing JwtService used for user auth).
  # The raw JWT is returned once on creation and cannot be retrieved again —
  # only a SHA-256 hash is stored in the database.
  #
  # Usage:
  #   result = Jwt::TokenGenerator.call(
  #     admin_user: current_user,
  #     restaurant: restaurant,
  #     name: 'POS Integration',
  #     scopes: ['menu:read', 'orders:read'],
  #     expires_in: 30.days,
  #     rate_limit_per_minute: 60,
  #     rate_limit_per_hour: 1000,
  #     description: 'Used by the Lightspeed POS connector',
  #   )
  #   result.success? # => true
  #   result.raw_jwt  # => 'eyJ...' (shown once only)
  #   result.token    # => AdminJwtToken instance
  class TokenGenerator
    Result = Struct.new(:success, :raw_jwt, :token, :error, keyword_init: true) do
      def success? = success
    end

    def self.call(**)
      new(**).call
    end

    def initialize(
      admin_user:,
      restaurant:,
      name:,
      scopes:,
      expires_in: 30.days,
      rate_limit_per_minute: 60,
      rate_limit_per_hour: 1000,
      description: nil
    )
      @admin_user           = admin_user
      @restaurant           = restaurant
      @name                 = name
      @scopes               = Array(scopes)
      @expires_in           = expires_in
      @rate_limit_per_minute = rate_limit_per_minute
      @rate_limit_per_hour   = rate_limit_per_hour
      @description = description
    end

    def call
      jti       = SecureRandom.uuid
      issued_at = Time.current
      expires_at = issued_at + @expires_in

      payload = {
        iss: 'mellow.menu',
        sub: "restaurant:#{@restaurant.id}",
        aud: 'mellow-api',
        exp: expires_at.to_i,
        iat: issued_at.to_i,
        jti: jti,
        restaurant_id: @restaurant.id,
        admin_user_id: @admin_user.id,
        scopes: @scopes,
        rate_limit: {
          per_minute: @rate_limit_per_minute,
          per_hour: @rate_limit_per_hour,
        },
      }

      raw_jwt    = JWT.encode(payload, secret_key, 'HS256')
      token_hash = Digest::SHA256.hexdigest(raw_jwt)

      token = AdminJwtToken.new(
        admin_user: @admin_user,
        restaurant: @restaurant,
        name: @name,
        description: @description,
        scopes: @scopes,
        token_hash: token_hash,
        expires_at: expires_at,
        rate_limit_per_minute: @rate_limit_per_minute,
        rate_limit_per_hour: @rate_limit_per_hour,
      )

      unless token.save
        return Result.new(
          success: false,
          error: token.errors.full_messages.join(', '),
        )
      end

      Result.new(success: true, raw_jwt: raw_jwt, token: token)
    rescue StandardError => e
      Rails.logger.error "[Jwt::TokenGenerator] Failed: #{e.message}"
      Result.new(success: false, error: e.message)
    end

    private

    def secret_key
      ENV.fetch('JWT_SECRET_KEY', Rails.application.secret_key_base)
    end
  end
end
