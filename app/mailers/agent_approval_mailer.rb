# frozen_string_literal: true

class AgentApprovalMailer < ApplicationMailer
  # Notify the reviewer that an agent action requires their approval.
  # @param approval [AgentApproval]
  # @param reviewer [User]
  def approval_requested(approval, reviewer)
    @approval   = approval
    @reviewer   = reviewer
    @run        = approval.agent_workflow_run
    @restaurant = @run.restaurant
    @workbench_url = restaurant_agent_workbench_url(@restaurant, @run, anchor: "approval-#{@approval.id}")

    mail(
      to: reviewer.email,
      subject: "AI action requires your approval — #{@restaurant.name}",
    )
  end

  # Notify the owner that an approval expired without review.
  # @param approval [AgentApproval]
  # @param owner    [User]
  def approval_expired(approval, owner)
    @approval   = approval
    @owner      = owner
    @run        = approval.agent_workflow_run
    @restaurant = @run.restaurant

    mail(
      to: owner.email,
      subject: "AI approval expired — action cancelled for #{@restaurant.name}",
    )
  end
end
