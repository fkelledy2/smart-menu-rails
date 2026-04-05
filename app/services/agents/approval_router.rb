# frozen_string_literal: true

module Agents
  # Agents::ApprovalRouter creates an AgentApproval record, determines the
  # appropriate reviewer based on risk_level, and sends a notification email.
  class ApprovalRouter
    Result = Struct.new(:success?, :approval, :error, keyword_init: true)

    def self.call(workflow_run:, action_type:, risk_level:, proposed_payload:, step: nil, idempotency_key: nil)
      new(
        workflow_run: workflow_run,
        action_type: action_type,
        risk_level: risk_level,
        proposed_payload: proposed_payload,
        step: step,
        idempotency_key: idempotency_key,
      ).call
    end

    def initialize(workflow_run:, action_type:, risk_level:, proposed_payload:, step: nil, idempotency_key: nil)
      @workflow_run     = workflow_run
      @action_type      = action_type.to_s
      @risk_level       = risk_level.to_s
      @proposed_payload = proposed_payload
      @step             = step
      @idempotency_key  = idempotency_key
    end

    def call
      expiry_hours = policy_expiry_hours
      approval = AgentApproval.create!(
        agent_workflow_run: @workflow_run,
        agent_workflow_step: @step,
        action_type: @action_type,
        risk_level: @risk_level,
        proposed_payload: @proposed_payload,
        status: 'pending',
        expires_at: expiry_hours.hours.from_now,
        idempotency_key: @idempotency_key,
      )

      @workflow_run.mark_awaiting_approval!

      reviewer = find_reviewer
      if reviewer
        AgentApprovalMailer.approval_requested(approval, reviewer).deliver_later
      end

      Result.new(success?: true, approval: approval)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success?: false, error: e.message)
    end

    private

    def policy_expiry_hours
      restaurant_id = @workflow_run.restaurant_id
      policy = AgentPolicy.active
        .where(action_type: @action_type)
        .where('restaurant_id = ? OR restaurant_id IS NULL', restaurant_id)
        .order(Arel.sql('restaurant_id IS NULL ASC'))
        .first
      policy&.approval_expiry_hours || AgentApproval::DEFAULT_EXPIRY_HOURS
    end

    # High-risk actions go to the restaurant owner (User); others go to any manager employee.
    def find_reviewer
      restaurant = @workflow_run.restaurant

      if @risk_level == 'high'
        restaurant.user
      else
        # Find a manager or admin employee who has a user account
        restaurant.employees
          .where(role: %w[manager admin])
          .joins(:user)
          .order(created_at: :asc)
          .first&.user || restaurant.user
      end
    end
  end
end
