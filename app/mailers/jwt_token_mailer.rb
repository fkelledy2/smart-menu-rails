# frozen_string_literal: true

class JwtTokenMailer < ApplicationMailer
  # Deliver the raw JWT to the restaurant contact with usage instructions.
  # The raw JWT is passed as a parameter and is NOT stored — it exists only
  # in the email delivery pipeline.
  def token_delivery(jwt_token:, recipient_email:, raw_jwt:)
    @jwt_token   = jwt_token
    @restaurant  = jwt_token.restaurant
    @raw_jwt     = raw_jwt
    @scopes      = jwt_token.scopes
    @expires_at  = jwt_token.expires_at

    mail(
      to: recipient_email,
      subject: "Your mellow.menu API token for #{@restaurant.name}",
    )
  end
end
