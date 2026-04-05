# frozen_string_literal: true

module Restaurants
  # AI Workbench — back-office UI for reviewing agent workflow runs,
  # approving/rejecting proposed actions, and inspecting audit logs.
  class AgentWorkbenchController < BaseController
    before_action :set_restaurant
    before_action :set_run, only: %i[show menu_import_review publish_menu_import optimization_review schedule_optimization]
    before_action :set_run_from_nested, only: %i[approve reject confirm_86 dismiss_recommendation]
    before_action :set_approval, only: %i[approve reject]
    before_action :set_ops_approval, only: %i[confirm_86 dismiss_recommendation]

    DIGEST_HISTORY_WEEKS = Agents::Workflows::ManagerDigestWorkflow::DIGEST_HISTORY_WEEKS
    MIN_DATA_DAYS = Agents::Workflows::MenuOptimizationWorkflow::MIN_ORDERS_WINDOW

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

    # GET /restaurants/:restaurant_id/agent_workbench/optimization
    # Lists recent menu optimization change set artifacts.
    def optimization
      authorize AgentWorkflowRun.new(restaurant: @restaurant), :index?

      @change_sets = AgentArtifact
        .joins(:agent_workflow_run)
        .where(
          agent_workflow_runs: { restaurant_id: @restaurant.id, workflow_type: 'menu_optimization' },
          artifact_type: 'menu_optimization_changeset',
        )
        .order(created_at: :desc)
        .limit(20)
        .includes(:agent_workflow_run)

      @has_enough_data = restaurant_has_enough_data?
    end

    # POST /restaurants/:restaurant_id/agent_workbench/run_optimization
    # Emits an on-demand menu_optimization.requested event and enqueues immediately.
    def run_optimization
      authorize AgentWorkflowRun.new(restaurant: @restaurant), :index?

      unless Flipper.enabled?(:agent_menu_optimization, @restaurant)
        redirect_to optimization_restaurant_agent_workbench_index_path(@restaurant),
                    alert: 'Menu optimisation is not enabled for this restaurant.'
        return
      end

      unless restaurant_has_enough_data?
        redirect_to optimization_restaurant_agent_workbench_index_path(@restaurant),
                    alert: "Not enough data yet — check back after #{MIN_DATA_DAYS} days of orders."
        return
      end

      if AgentWorkflowRun
          .for_restaurant(@restaurant.id)
          .where(workflow_type: 'menu_optimization')
          .active
          .exists?
        redirect_to optimization_restaurant_agent_workbench_index_path(@restaurant),
                    notice: 'An optimisation run is already in progress — check back shortly.'
        return
      end

      idempotency_key = "menu_optimization.requested:#{@restaurant.id}:#{Time.current.to_i}"

      event = AgentDomainEvent.publish!(
        event_type: 'menu_optimization.requested',
        source: @restaurant,
        payload: {
          'restaurant_id' => @restaurant.id,
          'triggered_at' => Time.current.iso8601,
          'on_demand' => true,
        },
        idempotency_key: idempotency_key,
      )

      run = AgentWorkflowRun.create!(
        restaurant: @restaurant,
        workflow_type: 'menu_optimization',
        trigger_event: 'menu_optimization.requested',
        status: 'pending',
        context_snapshot: event.payload,
      )

      Agents::MenuOptimizationWorkflowJob.perform_later(run.id)

      redirect_to optimization_restaurant_agent_workbench_index_path(@restaurant),
                  notice: 'Menu optimisation started — your change set will appear here within a few minutes.'
    end

    # GET /restaurants/:restaurant_id/agent_workbench/:id/optimization_review
    # Renders the change set review UI for a menu_optimization workflow run.
    def optimization_review
      authorize @run, :show?

      @artifact = @run.agent_artifacts
        .where(artifact_type: 'menu_optimization_changeset')
        .order(created_at: :desc)
        .first

      unless @artifact
        redirect_to restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'No change set found for this run.'
        return
      end

      @pending_approvals  = @run.agent_approvals.pending.order(created_at: :asc)
      @approved_actions   = @run.agent_approvals.where(status: 'approved').order(created_at: :asc)
      @rejected_actions   = @run.agent_approvals.where(status: 'rejected').order(created_at: :asc)

      content = @artifact.content.with_indifferent_access
      @all_actions    = Array(content[:actions])
      @advisory_items = Array(content[:advisory_pricing])

      # Build preview projection (in-memory — no writes to DB)
      @preview_items = build_preview_projection(@all_actions, @approved_actions)
    end

    # PATCH /restaurants/:restaurant_id/agent_workbench/:id/schedule_optimization
    # Sets scheduled_apply_at on the artifact so ApplyApprovedMenuChangesJob can pick it up.
    def schedule_optimization
      authorize @run, :show?

      @artifact = @run.agent_artifacts
        .where(artifact_type: 'menu_optimization_changeset')
        .order(created_at: :desc)
        .first

      unless @artifact
        redirect_to restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'No change set found for this run.'
        return
      end

      if @run.agent_approvals.pending.exists?
        redirect_to optimization_review_restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'All pending approvals must be resolved before scheduling rollout.'
        return
      end

      if @artifact.rejected? || @artifact.applied?
        redirect_to optimization_review_restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'This change set cannot be scheduled — it has already been rejected or applied.'
        return
      end

      apply_at = parse_scheduled_apply_at(params[:scheduled_apply_at])

      unless apply_at
        redirect_to optimization_review_restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'Invalid schedule time provided.'
        return
      end

      if apply_at <= Time.current
        redirect_to optimization_review_restaurant_agent_workbench_path(@restaurant, @run),
                    alert: 'Scheduled time must be in the future.'
        return
      end

      @artifact.update!(
        status: 'approved',
        approved_by: current_user,
        approved_at: Time.current,
        scheduled_apply_at: apply_at,
      )

      redirect_to optimization_review_restaurant_agent_workbench_path(@restaurant, @run),
                  notice: "Changes scheduled for rollout at #{apply_at.strftime('%H:%M on %d %b %Y')}."
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

    # POST /restaurants/:restaurant_id/agent_workbench/approvals/:id/confirm_86
    # Staff confirmation of an 86 recommendation — hides the menu item.
    def confirm_86
      authorize @ops_approval.agent_workflow_run, :show?

      unless @ops_approval.pending?
        respond_to do |format|
          format.json { render json: { error: 'Approval is no longer pending' }, status: :unprocessable_content }
          format.html { redirect_to restaurant_agent_workbench_index_path(@restaurant), alert: 'Approval is no longer pending.' }
        end
        return
      end

      @ops_approval.approve!(current_user, notes: 'Confirmed by staff via 86 recommendation card')

      result = Agents::Tools::FlagItemUnavailable.call(
        'menuitem_id' => @ops_approval.proposed_payload['menuitem_id'].to_i,
        'approval_id' => @ops_approval.id,
      )

      if result[:success]
        respond_to do |format|
          format.json { render json: { success: true, item_name: result[:item_name] } }
          format.html do
            redirect_to restaurant_agent_workbench_index_path(@restaurant),
                        notice: "#{result[:item_name]} has been 86'd and hidden from the menu."
          end
        end
      else
        respond_to do |format|
          format.json { render json: { error: result[:error] }, status: :unprocessable_content }
          format.html { redirect_to restaurant_agent_workbench_index_path(@restaurant), alert: result[:error] }
        end
      end
    rescue Agents::UnauthorisedActionError => e
      Rails.logger.warn("[AgentWorkbenchController#confirm_86] UnauthorisedActionError: #{e.message}")
      respond_to do |format|
        format.json { render json: { error: e.message }, status: :forbidden }
        format.html { redirect_to restaurant_agent_workbench_index_path(@restaurant), alert: 'Unauthorised action.' }
      end
    end

    # DELETE /restaurants/:restaurant_id/agent_workbench/approvals/:id/dismiss_recommendation
    # Staff dismissal of any agent recommendation card (no state change to menu/orders).
    def dismiss_recommendation
      authorize @ops_approval.agent_workflow_run, :show?

      @ops_approval.reject!(current_user, notes: 'Dismissed by staff via recommendation card')

      respond_to do |format|
        format.json { render json: { success: true, approval_id: @ops_approval.id } }
        format.html { redirect_to restaurant_agent_workbench_index_path(@restaurant), notice: 'Recommendation dismissed.' }
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

    def set_ops_approval
      @ops_approval = AgentApproval
        .joins(:agent_workflow_run)
        .where(agent_workflow_runs: { restaurant_id: @restaurant.id })
        .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.json { render json: { error: 'Approval not found' }, status: :not_found }
        format.html { redirect_to restaurant_agent_workbench_index_path(@restaurant), alert: 'Approval not found.' }
      end
    end

    def restaurant_has_enough_data?
      cutoff = MIN_DATA_DAYS.days.ago
      Ordr.where(restaurant_id: @restaurant.id).exists?(['created_at <= ?', cutoff])
    end

    # Build an in-memory preview of how the menu would look after applying approved changes.
    # Returns an array of item hashes with proposed changes applied — does NOT write to DB.
    def build_preview_projection(all_actions, approved_approvals)
      return [] if all_actions.blank?

      # Build a set of (action_type, target_id) pairs that were actually approved.
      # Coarse type-only matching would show all item_renames as changed even when
      # only a subset of target_ids were approved — same bug fixed in ApplyApprovedMenuChangesJob.
      approved_pairs = approved_approvals
        .pluck(:action_type, :proposed_payload)
        .to_set { |at, pp| [at, pp['target_id']&.to_i] }

      items = Menuitem
        .joins(:menusection)
        .where(menusections: { menu_id: @restaurant.menus.select(:id) })
        .where.not(archived: true)
        .select(
          'menuitems.id, menuitems.name, menuitems.description, menuitems.hidden, ' \
          'menuitems.sequence, menusections.id AS section_id, menusections.name AS section_name, ' \
          'menusections.sequence AS section_sequence',
        )
        .map { |mi| mi.attributes.merge('section_name' => mi.try(:section_name), 'section_id' => mi.try(:section_id), 'section_sequence' => mi.try(:section_sequence)) }

      item_map = items.each_with_object({}) { |i, h| h[i['id']] = i.dup }

      # Track updated section sequences so items can be sorted by projected section order.
      section_sequence_overrides = {}

      all_actions.each do |action|
        action_type = action['action_type'].to_s
        target_id   = action['target_id'].to_i
        next unless approved_pairs.include?([action_type, target_id])

        case action_type
        when 'item_rename'
          next unless item_map[target_id]

          item_map[target_id]['name']        = action['new_name']        if action['new_name'].present?
          item_map[target_id]['description'] = action['new_description'] if action['new_description'].present?
          item_map[target_id]['_changed']    = true
        when 'item_suppress'
          next unless item_map[target_id]

          item_map[target_id]['hidden']   = true
          item_map[target_id]['_changed'] = true
        when 'item_feature'
          next unless item_map[target_id]

          item_map[target_id]['hidden']   = false
          item_map[target_id]['_changed'] = true
        when 'section_reorder'
          # target_id is a menusection ID — update the projected sequence for that section
          # so items can be sorted into the correct order in the preview.
          new_seq = action['new_sequence'].to_i
          section_sequence_overrides[target_id] = new_seq if new_seq.positive?
        end
      end

      # Apply section sequence overrides to items and mark them changed.
      unless section_sequence_overrides.empty?
        item_map.each_value do |item|
          section_id = item['section_id'].to_i
          next unless section_sequence_overrides.key?(section_id)

          item['section_sequence'] = section_sequence_overrides[section_id]
          item['_changed'] = true
        end
      end

      item_map.values.sort_by { |i| [i['section_sequence'].to_i, i['section_name'].to_s, i['sequence'].to_i] }
    end

    def parse_scheduled_apply_at(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
