# frozen_string_literal: true

module Restaurants
  # AI Workbench — back-office UI for reviewing agent workflow runs,
  # approving/rejecting proposed actions, and inspecting audit logs.
  class AgentWorkbenchController < BaseController
    before_action :set_restaurant
    before_action :set_run, only: %i[show menu_import_review publish_menu_import]
    before_action :set_run_from_nested, only: %i[approve reject]
    before_action :set_approval, only: %i[approve reject]

    DIGEST_HISTORY_WEEKS = Agents::Workflows::ManagerDigestWorkflow::DIGEST_HISTORY_WEEKS

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

    # GET /restaurants/:restaurant_id/agent_workbench/digests
    # Lists the last DIGEST_HISTORY_WEEKS weeks of growth digest artifacts.
    def digests
      authorize AgentWorkflowRun.new(restaurant: @restaurant), :index?

      @digests = AgentArtifact
        .joins(:agent_workflow_run)
        .where(
          agent_workflow_runs: { restaurant_id: @restaurant.id, workflow_type: 'growth_digest' },
          artifact_type: 'growth_digest',
        )
        .where(agent_artifacts: { created_at: DIGEST_HISTORY_WEEKS.weeks.ago.. })
        .order(created_at: :desc)
        .limit(DIGEST_HISTORY_WEEKS)
    end

    # POST /restaurants/:restaurant_id/agent_workbench/generate_digest
    # Emits an on-demand manager_digest.requested event and enqueues immediately.
    def generate_digest
      authorize AgentWorkflowRun.new(restaurant: @restaurant), :index?

      unless Flipper.enabled?(:agent_growth_digest, @restaurant)
        redirect_to digests_restaurant_agent_workbench_index_path(@restaurant),
                    alert: 'Growth digest feature is not enabled for this restaurant.'
        return
      end

      if AgentWorkflowRun
          .for_restaurant(@restaurant.id)
          .where(workflow_type: 'growth_digest')
          .active
          .exists?
        redirect_to digests_restaurant_agent_workbench_index_path(@restaurant),
                    notice: 'A digest is already being generated — check back shortly.'
        return
      end

      idempotency_key = "manager_digest.requested:#{@restaurant.id}:#{Time.current.to_i}"

      event = AgentDomainEvent.publish!(
        event_type: 'manager_digest.requested',
        source: @restaurant,
        payload: {
          'restaurant_id' => @restaurant.id,
          'triggered_at' => Time.current.iso8601,
          'on_demand' => true,
        },
        idempotency_key: idempotency_key,
      )

      # Bypass normal Dispatcher for on-demand — create run and enqueue directly.
      run = AgentWorkflowRun.create!(
        restaurant: @restaurant,
        workflow_type: 'growth_digest',
        trigger_event: 'manager_digest.requested',
        status: 'pending',
        context_snapshot: event.payload,
      )

      Agents::ManagerDigestWorkflowJob.perform_later(run.id)

      redirect_to digests_restaurant_agent_workbench_index_path(@restaurant),
                  notice: 'Digest generation started — your digest will appear here within 10 minutes.'
    end

    # GET /restaurants/:restaurant_id/agent_workbench/:id/menu_import_review
    # Renders the diff review UI for a menu_import workflow run.
    def menu_import_review
      authorize @run, :show?

      @ocr_import = OcrMenuImport
        .where(restaurant: @restaurant, agent_workflow_run_id: @run.id)
        .includes(ocr_menu_sections: :ocr_menu_items)
        .first

      @artifact = @run.agent_artifacts.where(artifact_type: 'menu_import_draft').order(created_at: :desc).first
      @pending_approvals = @run.agent_approvals.pending.order(created_at: :asc).includes(:agent_workflow_step)

      # Load existing live menus for the diff view
      @existing_menus = @restaurant.menus.where.not(status: 'archived').includes(:menusections).limit(5)
    end

    # POST /restaurants/:restaurant_id/agent_workbench/:id/publish_menu_import
    # Publishes the approved draft to a live menu via ImportToMenu service.
    def publish_menu_import
      authorize @run, :show?

      ocr_import = OcrMenuImport
        .where(restaurant: @restaurant, agent_workflow_run_id: @run.id)
        .first

      unless ocr_import
        redirect_to restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'No import found for this workflow run.'
        return
      end

      if @run.agent_approvals.pending.exists?
        redirect_to menu_import_review_restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'All pending approvals must be resolved before publishing.'
        return
      end

      result = Agents::MenuImportPublisher.call(
        workflow_run: @run,
        ocr_import: ocr_import,
        restaurant: @restaurant,
        published_by: current_user,
      )

      if result.success?
        redirect_to restaurant_menu_path(@restaurant, result.menu),
                    notice: 'Menu successfully published from AI import.'
      else
        redirect_to menu_import_review_restaurant_agent_workbench_path(@restaurant, @run),
                    alert: "Publish failed: #{result.error}"
      end
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
