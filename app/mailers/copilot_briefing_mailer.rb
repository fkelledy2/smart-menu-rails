# frozen_string_literal: true

# Delivers staff briefing messages drafted via the Staff Copilot.
# Messages are always manager-reviewed before this mailer is called.
class CopilotBriefingMailer < ApplicationMailer
  # Send a staff briefing message drafted by the copilot to a team member.
  #
  # @param restaurant [Restaurant]
  # @param from_user  [User]      the manager who approved and sent the message
  # @param to_email   [String]    recipient email address
  # @param subject    [String]    message subject line
  # @param body       [String]    message body text
  def staff_briefing(restaurant:, from_user:, to_email:, subject:, body:)
    @restaurant = restaurant
    @from_user  = from_user
    @body       = body

    mail(
      to: to_email,
      subject: "[#{@restaurant.name}] #{subject}",
      from: "#{@restaurant.name} <admin@mellow.menu>",
    )
  end
end
