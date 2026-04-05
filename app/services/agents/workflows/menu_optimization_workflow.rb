# frozen_string_literal: true

module Agents
  module Workflows
    # Agents::Workflows::MenuOptimizationWorkflow orchestrates the 5-step menu
    # optimization pipeline. It is invoked by Agents::MenuOptimizationWorkflowJob.
    #
    # All analytics reads use the replica DB connection.
    # This agent produces a structured change set artifact containing proposed
    # actions that require manager approval before being applied to the live menu.
    # Price suggestions are advisory-only and never create AgentApproval records.
    #
    # Pipeline:
    #   1. read_performance   — tag items by performance metrics using replica DB
    #   2. optimisation_reason — LLM generates structured change set
    #   3. policy_validate    — check each action against AgentPolicy
    #   4. write_change_set   — persist AgentArtifact + AgentApproval records
    #   5. notify_manager     — email notification with link to review screen
    class MenuOptimizationWorkflow
      STEP_NAMES = %w[
        read_performance
        optimisation_reason
        policy_validate
        write_change_set
        notify_manager
      ].freeze

      # Action types that can appear in the change set.
      CHANGE_ACTION_TYPES = %w[
        section_reorder
        item_rename
        item_suppress
        item_feature
        image_queue
        price_suggestion
      ].freeze

      # Actions that require approval (never auto-approved except image_queue).
      APPROVAL_REQUIRED_ACTIONS = %w[section_reorder item_rename item_suppress item_feature].freeze

      # Actions that are auto-approved immediately.
      AUTO_APPROVE_ACTIONS = %w[image_queue].freeze

      # Price suggestions are advisory only — never create an AgentApproval record.
      ADVISORY_ONLY_ACTIONS = %w[price_suggestion].freeze

      LLM_MODEL         = 'gpt-4o'
      LLM_TEMPERATURE   = 0  # deterministic for change sets
      MIN_ORDERS_WINDOW = 14 # days — must have this many days of order data
      DATA_WINDOW_DAYS  = 7  # analyse last 7 days of orders

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
          # Re-check flag at each step per spec requirement
          unless Flipper.enabled?(:agent_menu_optimization, @restaurant)
            Rails.logger.info(
              "[MenuOptimizationWorkflow] agent_menu_optimization flag disabled mid-run " \
              "for restaurant #{@restaurant.id} — halting",
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

        return if halted

        @run.reload
        complete_if_finished
      rescue StandardError => e
        Rails.logger.error(
          "[MenuOptimizationWorkflow] Run #{@run.id} failed: #{e.message}\n" \
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
        when 'read_performance'    then step_read_performance
        when 'optimisation_reason' then step_optimisation_reason
        when 'policy_validate'     then step_policy_validate
        when 'write_change_set'    then step_write_change_set
        when 'notify_manager'      then step_notify_manager
        else
          raise "Unknown step: #{step.step_name}"
        end
      end

      # ---------------------------------------------------------------------------
      # Step 1: read_performance
      # Pull 7-day item metrics from analytics services on the replica DB.
      # Tag items as: high_margin / low_margin, high_conversion / low_conversion,
      # slow_mover / fast_mover, no_image.
      # ---------------------------------------------------------------------------
      def step_read_performance
        tagged_items = ApplicationRecord.connected_to(role: :reading) do
          build_tagged_items
        end

        {
          restaurant_id: @restaurant.id,
          restaurant_name: @restaurant.name,
          window_days: DATA_WINDOW_DAYS,
          tagged_items: tagged_items,
          total_items: tagged_items.size,
          analysis_week: "#{Date.current.year}-W#{Date.current.cweek.to_s.rjust(2, '0')}",
        }
      end

      # ---------------------------------------------------------------------------
      # Step 2: optimisation_reason
      # LLM generates a structured change set with concrete actions.
      # ---------------------------------------------------------------------------
      def step_optimisation_reason
        perf = completed_step_output('read_performance') || {}
        tagged_items = perf['tagged_items'] || []

        return empty_change_set if tagged_items.empty?

        system_prompt = build_optimization_prompt
        user_message  = build_user_message(perf, tagged_items)

        response = openai_client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: user_message },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parsed  = parse_json_from_llm(content)

        validate_and_sanitise_change_set(parsed, tagged_items)
      rescue JSON::ParserError => e
        Rails.logger.warn("[MenuOptimizationWorkflow] optimisation_reason JSON parse error: #{e.message}")
        empty_change_set
      end

      # ---------------------------------------------------------------------------
      # Step 3: policy_validate
      # Check each change action against AgentPolicy.
      # ---------------------------------------------------------------------------
      def step_policy_validate
        change_set = completed_step_output('optimisation_reason') || {}
        actions    = Array(change_set['actions'])

        classified = actions.map do |action|
          action_type = action['action_type'].to_s
          disposition = classify_action(action_type)
          action.merge('disposition' => disposition)
        end

        # Filter out advisory-only actions from the approvable list
        approvable  = classified.reject { |a| a['disposition'] == 'advisory' }
        advisory    = classified.select { |a| a['disposition'] == 'advisory' }

        {
          actions: classified,
          approvable_actions: approvable,
          advisory_actions: advisory,
          analysis_week: change_set['analysis_week'],
        }
      end

      # ---------------------------------------------------------------------------
      # Step 4: write_change_set
      # Write AgentArtifact + create AgentApproval records for each action.
      # image_queue actions are auto-approved and immediately enqueue image gen.
      # ---------------------------------------------------------------------------
      def step_write_change_set
        policy_output = completed_step_output('policy_validate') || {}
        perf_output   = completed_step_output('read_performance') || {}
        actions       = Array(policy_output['actions'])
        analysis_week = policy_output['analysis_week'] || perf_output['analysis_week']

        # Write the artifact
        artifact_content = {
          restaurant_id: @restaurant.id,
          analysis_week: analysis_week,
          actions: actions,
          advisory_pricing: Array(policy_output['advisory_actions'])
            .select { |a| a['action_type'] == 'price_suggestion' },
          generated_at: Time.current.iso8601,
        }

        result = Agents::ArtifactWriter.call(
          workflow_run: @run,
          artifact_type: 'menu_optimization_changeset',
          content: artifact_content,
        )

        raise "ArtifactWriter failed: #{result.error}" unless result.success?

        artifact = result.artifact
        step = @run.agent_workflow_steps.find_by(step_name: 'write_change_set')

        approvals_created = 0
        auto_approved     = 0

        actions.each do |action|
          action_type  = action['action_type'].to_s
          disposition  = action['disposition'].to_s
          target_id    = action['target_id']

          next if ADVISORY_ONLY_ACTIONS.include?(action_type)

          ikey = build_idempotency_key(analysis_week, action_type, target_id)

          # Skip if approval already exists (idempotency)
          next if AgentApproval.exists?(idempotency_key: ikey)

          # Skip if this action was recently rejected (within 14 days)
          next if recently_rejected?(action_type, target_id)

          if disposition == 'auto_approve'
            # Rescue RecordNotUnique in case a concurrent retry races past the
            # exists? check above and hits the DB unique index on idempotency_key.
            begin
              AgentApproval.create!(
                agent_workflow_run: @run,
                agent_workflow_step: step,
                action_type: action_type,
                risk_level: 'low',
                proposed_payload: action,
                status: 'approved',
                expires_at: 72.hours.from_now,
                idempotency_key: ikey,
                reviewed_at: Time.current,
              )
            rescue ActiveRecord::RecordNotUnique
              Rails.logger.info(
                "[MenuOptimizationWorkflow] Concurrent duplicate auto-approval for #{action_type}:#{target_id} — skipping",
              )
              next
            end

            # Auto-approved image_queue actions enqueue image generation immediately
            enqueue_image_generation(action) if action_type == 'image_queue'
            auto_approved += 1
          else
            # require_approval
            # Pass idempotency_key directly so it is set atomically at create! time,
            # avoiding the TOCTOU race of a separate update_column call.
            router_result = Agents::ApprovalRouter.call(
              workflow_run: @run,
              action_type: action_type,
              risk_level: 'low',
              proposed_payload: action.merge('idempotency_key' => ikey),
              step: step,
              idempotency_key: ikey,
            )
            approvals_created += 1 if router_result.success?
          end
        end

        {
          artifact_id: artifact.id,
          approvals_created: approvals_created,
          auto_approved: auto_approved,
        }
      end

      # ---------------------------------------------------------------------------
      # Step 5: notify_manager
      # Send notification email with link to the review screen.
      # ---------------------------------------------------------------------------
      def step_notify_manager
        change_set_output = completed_step_output('write_change_set') || {}
        artifact_id = change_set_output['artifact_id']

        artifact = AgentArtifact.find_by(id: artifact_id)
        return { emails_sent: 0 } unless artifact

        pending_count = @run.agent_approvals.pending.count
        recipients    = managers_and_owners

        recipients.each do |user|
          AgentOptimizationMailer.optimization_ready(@restaurant, artifact, user, pending_count).deliver_later
        end

        {
          artifact_id: artifact_id,
          emails_sent: recipients.size,
          pending_approvals: pending_count,
        }
      end

      # ---------------------------------------------------------------------------
      # Helpers
      # ---------------------------------------------------------------------------

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

      # Build tagged item hash from order data + menu structure using replica DB.
      # Caller must wrap in connected_to(role: :reading).
      def build_tagged_items
        since = DATA_WINDOW_DAYS.days.ago

        order_counts = Ordritem
          .joins(:ordr)
          .where(ordrs: { restaurant_id: @restaurant.id, created_at: since.. })
          .where.not(ordritems: { status: Ordritem.statuses[:removed] })
          .group(:menuitem_id)
          .pluck(:menuitem_id, Arel.sql('COUNT(*) AS cnt, COALESCE(SUM(ordritems.quantity), 0) AS qty'))
          .each_with_object({}) do |(mid, cnt, qty), h|
            h[mid] = { order_count: cnt.to_i, quantity: qty.to_i }
          end

        total_orders = @restaurant.ordrs.where(created_at: since..).count

        # Carry [menuitem, section_name] pairs through the flat_map to avoid
        # N+1 queries from mi.menusection inside the subsequent map.
        menuitem_section_pairs = @restaurant.menus
          .includes(menusections: { menuitems: %i[menuitem_costs genimage] })
          .flat_map do |menu|
            menu.menusections.flat_map do |section|
              section.menuitems.map { |mi| [mi, section.name.to_s] }
            end
          end
          .select { |(mi, _)| mi.respond_to?(:status) && mi.status.to_s == 'active' }
          .uniq { |(mi, _)| mi.id }

        # order_counts.values is a plain Ruby Array (not an AR relation), so .pluck cannot be used here.
        # rubocop:disable Rails/Pluck
        median_orders = compute_median(order_counts.values.map { |h| h[:order_count] })
        # rubocop:enable Rails/Pluck

        menuitem_section_pairs.map do |(mi, section_name)|
          counts     = order_counts[mi.id] || { order_count: 0, quantity: 0 }
          order_cnt  = counts[:order_count]
          margin_pct = mi.respond_to?(:profit_margin_percentage) ? mi.profit_margin_percentage.to_f : 0.0
          order_share = total_orders.positive? ? (order_cnt.to_f / total_orders) : 0.0
          has_image   = mi.respond_to?(:genimage) && mi.genimage.present?

          tags = compute_tags(
            order_cnt: order_cnt,
            median_orders: median_orders,
            margin_pct: margin_pct,
            order_share: order_share,
          )

          {
            'menuitem_id' => mi.id,
            'name' => mi.name.to_s,
            'description' => mi.try(:description).to_s,
            'price' => mi.try(:price).to_f,
            'section_id' => mi.menusection_id,
            'section_name' => section_name,
            'sequence' => mi.try(:sequence).to_i,
            'hidden' => mi.try(:hidden) || false,
            'order_count' => order_cnt,
            'order_share' => order_share.round(4),
            'margin_pct' => margin_pct,
            'has_image' => has_image,
            'tags' => tags,
          }
        end
      end

      def compute_tags(order_cnt:, median_orders:, margin_pct:, order_share:)
        tags = []
        tags << 'fast_mover'      if order_cnt.positive? && order_cnt >= [median_orders * 1.5, 1].max
        tags << 'slow_mover'      if order_cnt < [median_orders * 0.5, 1].min || order_cnt.zero?
        tags << 'high_margin'     if margin_pct >= 60.0
        tags << 'low_margin'      if margin_pct.positive? && margin_pct < 30.0
        tags << 'high_conversion' if order_share >= 0.15
        tags << 'low_conversion'  if order_share < 0.05 && order_cnt.zero?
        tags.uniq
      end

      def compute_median(values)
        return 0 if values.empty?

        sorted = values.sort
        mid    = sorted.size / 2
        sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
      end

      def build_optimization_prompt
        <<~PROMPT
          You are a menu optimization expert for restaurants. Analyse the 7-day item performance data
          and produce a structured change set with concrete, actionable improvements.

          You MUST return ONLY valid JSON with a single key "actions" containing an array of action objects.

          Each action object must have these fields:
          - "action_type": one of: section_reorder, item_rename, item_suppress, item_feature, image_queue, price_suggestion
          - "target_id": the menuitem_id (integer) or menusection_id for section_reorder
          - "target_name": human-readable name of the target
          - "reason": brief explanation (max 20 words)
          - action-specific fields:

          For section_reorder:
            "new_sequence": integer (target sequence position within section)

          For item_rename:
            "new_name": string (improved name)
            "new_description": string (improved description, or null to leave unchanged)

          For item_suppress:
            "suppress_permanent": boolean (true = hide indefinitely, false = time-gated)
            "suppress_from": ISO8601 datetime or null
            "suppress_until": ISO8601 datetime or null

          For item_feature:
            "featured": true

          For image_queue:
            (no extra fields — just action_type, target_id, target_name, reason)

          For price_suggestion:
            "suggested_price": float
            "advisory_note": string

          Rules:
          - Produce at most 10 total actions.
          - Never propose section_reorder or item_rename for top-performing items already working well.
          - Only propose image_queue for items tagged "slow_mover" or "low_conversion" AND has_image is false.
          - Only propose item_suppress for persistent slow movers (at least in slow_mover tag).
          - Only propose item_feature for high_margin AND (fast_mover OR high_conversion) items.
          - price_suggestion is ADVISORY ONLY — always include an advisory_note making this clear.
          - If data is insufficient, return an empty actions array: {"actions": []}
        PROMPT
      end

      def build_user_message(perf, tagged_items)
        {
          restaurant: perf['restaurant_name'],
          analysis_window_days: perf['window_days'],
          total_items: perf['total_items'],
          items: tagged_items,
        }.to_json
      end

      def validate_and_sanitise_change_set(parsed, tagged_items)
        actions  = Array(parsed['actions'])
        item_ids = tagged_items.to_set { |i| i['menuitem_id'] }
        section_ids = tagged_items.to_set { |i| i['section_id'] }

        # Remove any actions targeting unknown items/sections
        valid_actions = actions.select do |action|
          action_type = action['action_type'].to_s
          next false unless CHANGE_ACTION_TYPES.include?(action_type)

          if action_type == 'section_reorder'
            section_ids.include?(action['target_id'].to_i)
          else
            item_ids.include?(action['target_id'].to_i)
          end
        end

        perf_output = completed_step_output('read_performance') || {}

        {
          'actions' => valid_actions,
          'analysis_week' => perf_output['analysis_week'],
          'total_proposed' => valid_actions.size,
        }
      end

      def empty_change_set
        perf_output = completed_step_output('read_performance') || {}
        {
          'actions' => [],
          'analysis_week' => perf_output['analysis_week'],
          'total_proposed' => 0,
        }
      end

      def classify_action(action_type)
        return 'auto_approve'  if AUTO_APPROVE_ACTIONS.include?(action_type)
        return 'advisory'      if ADVISORY_ONLY_ACTIONS.include?(action_type)

        'require_approval'
      end

      def build_idempotency_key(analysis_week, action_type, target_id)
        raw = "#{@restaurant.id}:#{analysis_week}:#{action_type}:#{target_id}"
        Digest::SHA256.hexdigest(raw)
      end

      def recently_rejected?(action_type, target_id)
        cutoff = 14.days.ago

        AgentApproval
          .joins(:agent_workflow_run)
          .where(
            agent_workflow_runs: { restaurant_id: @restaurant.id },
            action_type: action_type,
            status: 'rejected',
          )
          .where(agent_approvals: { created_at: cutoff.. })
          .exists?(['proposed_payload->>? = ?', 'target_id', target_id.to_s])
      end

      def enqueue_image_generation(action)
        menuitem_id = action['target_id'].to_i
        menuitem = Menuitem.find_by(id: menuitem_id)
        return unless menuitem

        # Skip if a genimage already exists for this menuitem
        return if menuitem.genimage.present?

        # Create a Genimage record and enqueue generation.
        # Guard against duplicate concurrent creates with the unique DB constraint.
        begin
          genimage = Genimage.create!(
            menuitem: menuitem,
            restaurant_id: @restaurant.id,
            name: 'agent_queued',
          )
        rescue ActiveRecord::RecordNotUnique
          Rails.logger.info(
            "[MenuOptimizationWorkflow] Genimage already exists for menuitem #{menuitem_id} — skipping",
          )
          return
        end
        MenuItemImageGeneratorJob.perform_later(genimage.id)
      rescue StandardError => e
        Rails.logger.warn(
          "[MenuOptimizationWorkflow] Failed to queue image for menuitem #{action['target_id']}: #{e.message}",
        )
      end

      def managers_and_owners
        Employee
          .where(restaurant: @restaurant, role: %i[manager admin], status: :active)
          .includes(:user)
          .filter_map(&:user)
          .uniq(&:id)
      end

      def parse_json_from_llm(content)
        stripped = content.gsub(/```(?:json)?\n?/, '').gsub('```', '').strip
        JSON.parse(stripped)
      rescue JSON::ParserError
        match = content.match(/\{.*\}/m)
        raise JSON::ParserError, 'No JSON object found in LLM response' unless match

        JSON.parse(match[0])
      end
    end
  end
end
