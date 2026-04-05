# frozen_string_literal: true

module Agents
  module Workflows
    # Agents::Workflows::ReputationFeedbackWorkflow orchestrates the 4-step
    # reputation triage pipeline. It is triggered by domain events:
    #   - rating.low (1–2 stars at checkout)
    #   - complaint.submitted
    #   - review.received
    #   - payment.abandoned
    #
    # SAFETY CONTRACT: This workflow NEVER sends any communication to customers
    # autonomously. All outbound messages require explicit manager approval.
    # All AgentApproval records created here have risk_level: high.
    #
    # Pipeline:
    #   1. read_context         — load order, items, table, rating/review text
    #   2. classify_and_reason  — LLM severity classification + draft response(s)
    #   3. write_recovery_draft — persist AgentArtifact + AgentApproval records
    #   4. notify_manager       — email + optional UserChannel push
    class ReputationFeedbackWorkflow
      STEP_NAMES = %w[
        read_context
        classify_and_reason
        write_recovery_draft
        notify_manager
      ].freeze

      # Supported signal types (from domain event payload)
      SIGNAL_TYPES = %w[rating.low complaint.submitted review.received payment.abandoned].freeze

      # Severity levels produced by LLM classification
      SEVERITY_LEVELS = %w[low medium high].freeze

      # Root cause categories
      ROOT_CAUSES = %w[wait_time wrong_item quality price service other].freeze

      # Suggested actions surfaced in the approval card
      SUGGESTED_ACTIONS = %w[discount_offer comp direct_message no_action].freeze

      # Systemic issue detection: same root_cause within this window
      SYSTEMIC_ISSUE_WINDOW_DAYS  = 7
      SYSTEMIC_ISSUE_MIN_COUNT    = 3

      LLM_MODEL       = 'gpt-4o'
      LLM_TEMPERATURE = 0 # deterministic for triage

      def self.call(workflow_run)
        new(workflow_run).call
      end

      def initialize(workflow_run)
        @run        = workflow_run
        @restaurant = workflow_run.restaurant
      end

      def call
        provision_steps!
        @run.mark_running! if @run.pending?

        halted = false
        STEP_NAMES.each_with_index do |name, idx|
          unless Flipper.enabled?(:agent_reputation_feedback, @restaurant)
            Rails.logger.info(
              "[ReputationFeedbackWorkflow] flag disabled mid-run for restaurant #{@restaurant.id} — halting",
            )
            @run.mark_failed!('Feature flag disabled during run')
            halted = true
            break
          end

          step = @run.agent_workflow_steps.find_by(step_name: name, step_index: idx)
          next if step.nil? || step.completed? || step.skipped?

          execute_step(step)
          @run.reload
          break if @run.failed?
        end

        @run.reload
        complete_if_finished unless halted
      rescue StandardError => e
        Rails.logger.error(
          "[ReputationFeedbackWorkflow] Run #{@run.id} failed: #{e.message}\n" \
          "#{e.backtrace&.first(5)&.join("\n")}",
        )
        @run.mark_failed!(e.message)
      end

      private

      def provision_steps!
        existing_names = @run.agent_workflow_steps.pluck(:step_name)
        STEP_NAMES.each_with_index do |name, idx|
          next if existing_names.include?(name)

          @run.agent_workflow_steps.create!(
            step_name: name,
            step_index: idx,
            status: 'pending',
            input_snapshot: {},
            retry_count: 0,
          )
        end
      end

      def execute_step(step)
        step.mark_running!
        result = dispatch_step(step)
        step.mark_completed!(result)
      rescue StandardError => e
        step.mark_failed!(e)
        raise
      end

      def dispatch_step(step)
        case step.step_name
        when 'read_context'        then step_read_context
        when 'classify_and_reason' then step_classify_and_reason
        when 'write_recovery_draft' then step_write_recovery_draft
        when 'notify_manager' then step_notify_manager
        else raise "Unknown step: #{step.step_name}"
        end
      end

      # -------------------------------------------------------------------------
      # Step 1: read_context
      # Load the full order context for the affected session.
      # -------------------------------------------------------------------------
      def step_read_context
        payload      = @run.context_snapshot || {}
        signal_type  = payload['signal_type'] || @run.trigger_event
        ordr_id      = payload['ordr_id']
        review_text  = payload['review_text'].to_s
        complaint_text = payload['complaint_text'].to_s
        stars        = payload['stars']

        ordr_context = build_ordr_context(ordr_id)

        {
          'signal_type' => signal_type,
          'stars' => stars,
          'review_text' => review_text,
          'complaint_text' => complaint_text,
          'ordr_id' => ordr_id,
          'ordr_context' => ordr_context,
          'restaurant_name' => @restaurant.name,
        }
      end

      # -------------------------------------------------------------------------
      # Step 2: classify_and_reason
      # LLM classifies severity, infers root cause, drafts recovery message(s).
      # -------------------------------------------------------------------------
      def step_classify_and_reason
        context      = completed_step_output('read_context') || {}
        signal_type  = context['signal_type'].to_s
        ordr_context = context['ordr_context'] || {}

        # Payment abandoned has no LLM step — rule-based only
        if signal_type == 'payment.abandoned'
          return {
            'severity' => 'high',
            'root_cause' => 'other',
            'suggested_action' => 'no_action',
            'draft_message' => nil,
            'draft_review_response' => nil,
            'fast_path' => true,
          }
        end

        llm_classify(context, ordr_context, signal_type)
      end

      # -------------------------------------------------------------------------
      # Step 3: write_recovery_draft
      # Persist AgentArtifact + AgentApproval records for manager review.
      # -------------------------------------------------------------------------
      def step_write_recovery_draft
        context = completed_step_output('read_context') || {}
        classification = completed_step_output('classify_and_reason') || {}
        step = @run.agent_workflow_steps.find_by(step_name: 'write_recovery_draft')

        artifact_content = {
          'signal_type' => context['signal_type'],
          'ordr_id' => context['ordr_id'],
          'stars' => context['stars'],
          'review_text' => context['review_text'],
          'complaint_text' => context['complaint_text'],
          'severity' => classification['severity'],
          'root_cause' => classification['root_cause'],
          'suggested_action' => classification['suggested_action'],
          'draft_message' => classification['draft_message'],
          'draft_review_response' => classification['draft_review_response'],
          'ordr_context' => context['ordr_context'],
          'restaurant_name' => context['restaurant_name'],
          'classified_at' => Time.current.iso8601,
        }

        result = Agents::ArtifactWriter.call(
          workflow_run: @run,
          artifact_type: 'reputation_recovery',
          content: artifact_content,
        )

        unless result.success?
          raise "ArtifactWriter failed: #{result.error}"
        end

        artifact = result.artifact

        # Create approval record if there is an actionable draft message or review response
        approval = nil
        if has_outbound_action?(classification)
          idempotency_key = "reputation_recovery:#{@run.id}:send_message"

          approval_result = Agents::ApprovalRouter.call(
            workflow_run: @run,
            action_type: 'send_recovery_message',
            risk_level: 'high',
            proposed_payload: {
              'artifact_id' => artifact.id,
              'signal_type' => context['signal_type'],
              'ordr_id' => context['ordr_id'],
              'draft_message' => classification['draft_message'],
              'draft_review_response' => classification['draft_review_response'],
              'suggested_action' => classification['suggested_action'],
            },
            step: step,
            idempotency_key: idempotency_key,
          )

          approval = approval_result.approval if approval_result.success?
        end

        # Check for systemic issue pattern
        systemic_note = check_systemic_issue(classification['root_cause'])

        {
          'artifact_id' => artifact.id,
          'approval_id' => approval&.id,
          'artifact_type' => 'reputation_recovery',
          'severity' => classification['severity'],
          'systemic_issue' => systemic_note,
          'written_at' => Time.current.iso8601,
        }
      end

      # -------------------------------------------------------------------------
      # Step 4: notify_manager
      # Send email notification + optional UserChannel push for high-severity.
      # -------------------------------------------------------------------------
      def step_notify_manager
        draft_output = completed_step_output('write_recovery_draft') || {}
        context      = completed_step_output('read_context') || {}
        classification = completed_step_output('classify_and_reason') || {}

        artifact = AgentArtifact.find_by(id: draft_output['artifact_id'])
        reviewer = find_reviewer

        notifications_sent = 0

        if reviewer && artifact
          AgentReputationMailer.reputation_alert(
            restaurant: @restaurant,
            artifact: artifact,
            recipient: reviewer,
            severity: draft_output['severity'],
            signal_type: context['signal_type'],
            systemic_issue: draft_output['systemic_issue'],
          ).deliver_later

          notifications_sent += 1
        end

        # High-severity signals also get a UserChannel push
        if draft_output['severity'] == 'high' || context['signal_type'] == 'payment.abandoned'
          push_manager_channel_alert!(context, classification, draft_output)
        end

        # Systemic issue advisory push (independent of severity)
        if draft_output['systemic_issue'].present?
          push_systemic_issue_alert!(draft_output['systemic_issue'])
        end

        {
          'notifications_sent' => notifications_sent,
          'reviewer_id' => reviewer&.id,
          'notified_at' => Time.current.iso8601,
        }
      end

      # -------------------------------------------------------------------------
      # LLM classification
      # -------------------------------------------------------------------------
      def llm_classify(context, ordr_context, signal_type)
        system_prompt = build_classification_system_prompt(signal_type)
        user_content  = build_classification_user_content(context, ordr_context)

        response = openai_client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: user_content },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parse_llm_classification(content)
      rescue StandardError => e
        Rails.logger.warn("[ReputationFeedbackWorkflow] LLM classify failed: #{e.message} — using fallback")
        fallback_classification(context)
      end

      def build_classification_system_prompt(signal_type)
        <<~PROMPT
          You are a restaurant reputation management assistant. Analyse the customer signal below.

          IMPORTANT: You MUST only reference order items, prices, and details that are explicitly
          listed in the order context provided. Do not invent or hallucinate any menu items or prices.

          Return ONLY valid JSON with these exact keys:
          {
            "severity": "low"|"medium"|"high",
            "root_cause": "wait_time"|"wrong_item"|"quality"|"price"|"service"|"other",
            "suggested_action": "discount_offer"|"comp"|"direct_message"|"no_action",
            "draft_message": "personalised recovery message for the manager to send (or null if no_action)",
            "draft_review_response": "public review response (only for review.received signal; otherwise null)"
          }

          Severity guide:
          - high: 1-star rating, food safety complaint, payment issue, or review mentioning sickness/health
          - medium: 2-star rating, service complaint, wrong item delivered
          - low: 3-star rating, minor suggestion, general feedback

          Signal type: #{signal_type}
        PROMPT
      end

      def build_classification_user_content(context, ordr_context)
        parts = []
        parts << "Signal type: #{context['signal_type']}"
        parts << "Stars: #{context['stars']}" if context['stars']
        parts << "Review text: #{context['review_text']}" if context['review_text'].present?
        parts << "Complaint: #{context['complaint_text']}" if context['complaint_text'].present?
        parts << "Restaurant: #{context['restaurant_name']}"

        if ordr_context.present?
          parts << "\nOrder context:"
          parts << "  Table: #{ordr_context['table_name']}"
          parts << "  Order status: #{ordr_context['status']}"
          parts << "  Items ordered: #{Array(ordr_context['items']).pluck('name').join(', ')}"
          parts << "  Total: #{ordr_context['gross']}" if ordr_context['gross']
          parts << "  Order created: #{ordr_context['created_at']}"
        end

        parts.join("\n")
      end

      def parse_llm_classification(content)
        stripped = content.gsub(/```(?:json)?\n?/, '').gsub('```', '').strip
        parsed   = JSON.parse(stripped)

        {
          'severity' => validated_severity(parsed['severity']),
          'root_cause' => validated_root_cause(parsed['root_cause']),
          'suggested_action' => validated_suggested_action(parsed['suggested_action']),
          'draft_message' => parsed['draft_message'].to_s.presence,
          'draft_review_response' => parsed['draft_review_response'].to_s.presence,
          'fast_path' => false,
        }
      rescue JSON::ParserError => e
        Rails.logger.warn("[ReputationFeedbackWorkflow] JSON parse error: #{e.message}")
        fallback_classification({})
      end

      def fallback_classification(_context)
        {
          'severity' => 'medium',
          'root_cause' => 'other',
          'suggested_action' => 'direct_message',
          'draft_message' => nil,
          'draft_review_response' => nil,
          'fast_path' => true,
        }
      end

      def validated_severity(value)
        SEVERITY_LEVELS.include?(value.to_s) ? value.to_s : 'medium'
      end

      def validated_root_cause(value)
        ROOT_CAUSES.include?(value.to_s) ? value.to_s : 'other'
      end

      def validated_suggested_action(value)
        SUGGESTED_ACTIONS.include?(value.to_s) ? value.to_s : 'direct_message'
      end

      # -------------------------------------------------------------------------
      # Order context builder
      # -------------------------------------------------------------------------
      def build_ordr_context(ordr_id)
        return {} if ordr_id.blank?

        ordr = Ordr
          .where(restaurant_id: @restaurant.id)
          .includes(:tablesetting, ordritems: :menuitem, ordrparticipants: [])
          .find_by(id: ordr_id)

        return {} unless ordr

        items = ordr.ordritems.reject { |i| i.status.to_s == 'removed' }.map do |oi|
          {
            'name' => oi.menuitem&.name || 'Item',
            'quantity' => oi.quantity,
            'status' => oi.status.to_s,
          }
        end

        customer_participant = ordr.ordrparticipants.find { |p| p.role.to_s == 'customer' }

        {
          'ordr_id' => ordr.id,
          'table_name' => ordr.tablesetting&.name || "Order ##{ordr.id}",
          'status' => ordr.status.to_s,
          'gross' => ordr.gross,
          'items' => items,
          'item_count' => items.size,
          'customer_name' => customer_participant&.name,
          'created_at' => ordr.created_at.iso8601,
          'updated_at' => ordr.updated_at.iso8601,
        }
      end

      # -------------------------------------------------------------------------
      # Systemic issue detection
      # -------------------------------------------------------------------------
      def check_systemic_issue(root_cause)
        return nil if root_cause.blank? || root_cause == 'other'

        since = SYSTEMIC_ISSUE_WINDOW_DAYS.days.ago
        count = AgentArtifact
          .joins(:agent_workflow_run)
          .where(
            agent_workflow_runs: { restaurant_id: @restaurant.id, workflow_type: 'reputation_feedback' },
            artifact_type: 'reputation_recovery',
          )
          .where(agent_artifacts: { created_at: since.. })
          .where("agent_artifacts.content->>'root_cause' = ?", root_cause)
          .count

        # +1 for the current signal being processed
        total = count + 1

        if total >= SYSTEMIC_ISSUE_MIN_COUNT
          "#{total} #{root_cause.humanize.downcase} issues in the last #{SYSTEMIC_ISSUE_WINDOW_DAYS} days — possible systemic problem."
        end
      end

      # -------------------------------------------------------------------------
      # ActionCable push helpers
      # -------------------------------------------------------------------------
      def push_manager_channel_alert!(context, classification, draft_output)
        manager_user_ids.each do |uid|
          payload = {
            action: 'reputation_alert',
            type: context['signal_type'],
            ordr_id: context['ordr_id'],
            stars: context['stars'],
            severity: draft_output['severity'],
            root_cause: classification['root_cause'],
            suggested_action: classification['suggested_action'],
            message: "#{signal_label(context['signal_type'])} requires your attention.",
            review_url: reputation_review_url_for(@run),
            timestamp: Time.current.iso8601,
          }
          ActionCable.server.broadcast("user_#{uid}_channel", payload)
        end
      end

      def push_systemic_issue_alert!(note)
        manager_user_ids.each do |uid|
          payload = {
            action: 'systemic_issue_alert',
            message: note,
            restaurant_id: @restaurant.id,
            timestamp: Time.current.iso8601,
          }
          ActionCable.server.broadcast("user_#{uid}_channel", payload)
        end
      end

      # -------------------------------------------------------------------------
      # Helpers
      # -------------------------------------------------------------------------
      def has_outbound_action?(classification)
        classification['draft_message'].present? ||
          classification['draft_review_response'].present?
      end

      def signal_label(signal_type)
        case signal_type
        when 'rating.low'          then 'Low rating'
        when 'complaint.submitted' then 'Customer complaint'
        when 'review.received'     then 'New review'
        when 'payment.abandoned'   then 'Abandoned payment'
        else 'Customer feedback'
        end
      end

      def reputation_review_url_for(run)
        Rails.application.routes.url_helpers.reputation_review_restaurant_agent_workbench_url(
          @restaurant,
          run,
          host: Rails.application.config.action_mailer.default_url_options[:host],
        )
      rescue StandardError
        nil
      end

      def manager_user_ids
        Employee
          .where(restaurant: @restaurant, role: %i[manager admin], status: :active)
          .includes(:user)
          .filter_map { |e| e.user&.id }
          .uniq
      rescue StandardError => e
        Rails.logger.warn("[ReputationFeedbackWorkflow] manager_user_ids error: #{e.message}")
        []
      end

      def find_reviewer
        @restaurant.user
      rescue StandardError
        nil
      end

      def completed_step_output(step_name)
        step = @run.agent_workflow_steps.find_by(step_name: step_name, status: 'completed')
        step&.output_snapshot
      end

      def openai_client
        @openai_client ||= OpenaiClient.new
      end

      def complete_if_finished
        return if @run.failed? || @run.cancelled?

        all_done = @run.agent_workflow_steps.reload.all? { |s| s.completed? || s.skipped? }
        @run.mark_completed! if all_done
      end
    end
  end
end
