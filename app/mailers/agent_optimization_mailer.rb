# frozen_string_literal: true

# AgentOptimizationMailer notifies restaurant managers and owners when a new
# menu optimization change set is ready for review. Uses the branded mailer layout.
class AgentOptimizationMailer < ApplicationMailer
  # @param restaurant    [Restaurant]
  # @param artifact      [AgentArtifact] — type: menu_optimization_changeset
  # @param recipient     [User]
  # @param pending_count [Integer] number of pending approval actions
  def optimization_ready(restaurant, artifact, recipient, pending_count = 0)
    @restaurant    = restaurant
    @artifact      = artifact
    @recipient     = recipient
    @content       = artifact.content.with_indifferent_access
    @pending_count = pending_count
    @review_url    = optimization_restaurant_agent_workbench_index_url(@restaurant)

    mail(
      to: recipient.email,
      subject: "Menu optimisation ready to review — #{@restaurant.name}",
    )
  end
end
