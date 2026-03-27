# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  default to: proc { @admin_user&.email }

  # Notify the issuing admin that a JWT token is expiring in 7 days.
  def jwt_token_expiry_warning(jwt_token)
    @jwt_token  = jwt_token
    @admin_user = jwt_token.admin_user
    @restaurant = jwt_token.restaurant

    mail(
      to: @admin_user.email,
      subject: "Action required: API token '#{@jwt_token.name}' expires in 7 days",
    )
  end
end
