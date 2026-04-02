# frozen_string_literal: true

module Restaurants
  # AI Workbench — back-office UI for reviewing agent workflow runs,
  # approving/rejecting proposed actions, and inspecting audit logs.
  class AgentWorkbenchController < BaseController
    before_action :set_restaurant
    before_action :set_run, only: %i[show]
    before_action :set_run_from_nested, only: %i[approve reject]
    before_action :set_approval, only: %i[approve reject]

    # GET /restaurants/:restaurant_id/agent_workbench
    def index
      authorize AgentWorkflowRun.new(restaurant: @restaurant), :index?

      scope = policy_scope(AgentWorkflowRun)
        .for_restaurant(@restaurant.id)
        .recent
        .includes(:agent_artifacts, :agent_approvals)
      @pagy, @runs = pagy(scope, items: 20)
    end

    # GET /restaurants/:restaurant_id/agent_workbench/:id
    def show
      authorize @run, :show?

      @steps = @run.agent_workflow_steps.ordered.includes(:tool_invocation_logs)
      @artifacts = @run.agent_artifacts.order(created_at: :desc)
      @approvals = @run.agent_approvals.order(created_at: :desc).includes(:reviewer)
    end

    # PATCH /restaurants/:restaurant_id/agent_workbench/:agent_workbench_id/approvals/:id/approve
    def approve
      authorize @run, :show?

      if @approval.expired_at_time?
        redirect_to restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'This approval has expired and cannot be approved.'
        return
      end

      if @approval.approve!(current_user, notes: params[:reviewer_notes])
        # Resume the workflow run if it is still awaiting approval
        @run.reload
        Agents::DispatchDomainEventJob.perform_later(@run.id) if @run.awaiting_approval?

        redirect_to restaurant_agent_workbench_path(@restaurant, @run),
                    notice: 'Action approved. The workflow will resume shortly.'
      else
        redirect_to restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'Could not approve — please try again.'
      end
    end

    # PATCH /restaurants/:restaurant_id/agent_workbench/:agent_workbench_id/approvals/:id/reject
    def reject
      authorize @run, :show?

      @approval.reject!(current_user, notes: params[:reviewer_notes])

      @run.reload
      @run.mark_failed!('Rejected by reviewer') if @run.awaiting_approval?

      redirect_to restaurant_agent_workbench_path(@restaurant, @run),
                  notice: 'Action rejected. No changes were made.'
    end

    private

    def set_run
      @run = AgentWorkflowRun.for_restaurant(@restaurant.id).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to restaurant_agent_workbench_index_path(@restaurant), alert: 'Workflow run not found.'
    end

    def set_run_from_nested
      @run = AgentWorkflowRun.for_restaurant(@restaurant.id).find(params[:agent_workbench_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to restaurant_agent_workbench_index_path(@restaurant), alert: 'Workflow run not found.'
    end

    def set_approval
      @approval = AgentApproval
        .joins(:agent_workflow_run)
        .where(agent_workflow_runs: { restaurant_id: @restaurant.id })
        .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to restaurant_agent_workbench_index_path(@restaurant), alert: 'Approval not found.'
    end
  end
end
