# frozen_string_literal: true

# AgentRecoveryMailer delivers manager-approved recovery messages to customers.
# This mailer is ONLY invoked after explicit manager approval — never autonomously.
# Uses the branded mailer layout (Feature #2).
class AgentRecoveryMailer < ApplicationMailer
  # @param restaurant    [Restaurant]
  # @param to_email      [String] customer email address
  # @param message_body  [String] manager-approved message text
  # @param ordr_id       [Integer] for reference
  def recovery_message(restaurant:, to_email:, message_body:, ordr_id: nil)
    @restaurant   = restaurant
    @message_body = message_body
    @ordr_id      = ordr_id

    mail(
      to: to_email,
      subject: "A message from #{@restaurant.name}",
    )
  end
end
