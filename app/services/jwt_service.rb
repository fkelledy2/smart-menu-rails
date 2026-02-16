# frozen_string_literal: true

class JwtService
  SECRET_KEY = Rails.application.secret_key_base
  TOKEN_TTL = 1.hour
  DENYLIST_PREFIX = 'jwt_denied:'

  def self.encode(payload, exp = TOKEN_TTL.from_now)
    payload[:exp] = exp.to_i
    payload[:jti] ||= SecureRandom.uuid
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    payload = ActiveSupport::HashWithIndifferentAccess.new(decoded)

    # Check denylist
    if payload[:jti].present? && denied?(payload[:jti])
      Rails.logger.warn "JWT token denied (revoked): jti=#{payload[:jti]}"
      return nil
    end

    payload
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end

  def self.generate_token_for_user(user)
    payload = {
      user_id: user.id,
      email: user.email,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
    }
    encode(payload)
  end

  def self.user_from_token(token)
    return nil unless token

    decoded = decode(token)
    return nil unless decoded

    User.find_by(id: decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    nil
  end

  # Revoke a token by adding its jti to the denylist.
  # The denylist entry expires when the token would have expired anyway.
  def self.revoke!(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    jti = decoded['jti']
    exp = decoded['exp']
    return unless jti

    ttl = [exp.to_i - Time.current.to_i, 0].max
    Rails.cache.write("#{DENYLIST_PREFIX}#{jti}", true, expires_in: ttl.seconds)
  rescue JWT::DecodeError
    nil
  end

  def self.denied?(jti)
    Rails.cache.read("#{DENYLIST_PREFIX}#{jti}").present?
  end
end
