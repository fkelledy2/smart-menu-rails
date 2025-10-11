# frozen_string_literal: true

class JwtService
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    ActiveSupport::HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    Rails.logger.warn "JWT decode error: #{e.message}"
    nil
  end

  def self.generate_token_for_user(user)
    payload = {
      user_id: user.id,
      email: user.email,
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
end
