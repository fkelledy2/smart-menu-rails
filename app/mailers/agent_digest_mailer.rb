# frozen_string_literal: true

# AgentDigestMailer delivers the weekly (or on-demand) growth digest to restaurant
# managers and owners. Uses the branded mailer layout.
class AgentDigestMailer < ApplicationMailer
  # Send the weekly scheduled digest to a manager/owner.
  # @param restaurant [Restaurant]
  # @param artifact   [AgentArtifact] — type: growth_digest, status: approved
  # @param recipient  [User]
  def weekly_digest(restaurant, artifact, recipient)
    @restaurant = restaurant
    @artifact   = artifact
    @recipient  = recipient
    @content    = artifact.content.with_indifferent_access
    @workbench_url = restaurant_agent_workbench_index_url(@restaurant)

    mail(
      to: recipient.email,
      subject: "Your weekly growth digest — #{@restaurant.name}",
    )
  end

  # Send an on-demand digest triggered by "Generate Now" button.
  # @param restaurant [Restaurant]
  # @param artifact   [AgentArtifact]
  # @param recipient  [User]
  def on_demand_digest(restaurant, artifact, recipient)
    @restaurant = restaurant
    @artifact   = artifact
    @recipient  = recipient
    @content    = artifact.content.with_indifferent_access
    @workbench_url = restaurant_agent_workbench_index_url(@restaurant)

    mail(
      to: recipient.email,
      subject: "Your growth digest is ready — #{@restaurant.name}",
    )
  end
end
