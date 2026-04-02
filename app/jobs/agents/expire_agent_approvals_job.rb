# frozen_string_literal: true

module Agents
  # Marks expired AgentApproval records and notifies the restaurant owner.
  # Runs every hour via Sidekiq cron.
  class ExpireAgentApprovalsJob < ApplicationJob
    queue_as :agent_low

    def perform
      expired = AgentApproval.expired_but_not_marked.includes(agent_workflow_run: :restaurant)

      expired.find_each do |approval|
        approval.expire!

        restaurant = approval.agent_workflow_run.restaurant
        owner      = restaurant.user
        next unless owner

        AgentApprovalMailer.approval_expired(approval, owner).deliver_later
      rescue StandardError => e
        Rails.logger.error("[Agents::ExpireAgentApprovalsJob] Failed to expire approval #{approval.id}: #{e.message}")
      end
    end
  end
end
