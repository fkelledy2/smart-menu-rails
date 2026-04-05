# frozen_string_literal: true

module Agents
  module Workflows
    # Agents::Workflows::ServiceOperationsWorkflow orchestrates the 4-step real-time
    # kitchen operations pipeline. It is invoked by Agents::ServiceOperationsWorkflowJob.
    #
    # SAFETY CONTRACT: This workflow NEVER autonomously modifies any Ordr, Ordritem,
    # or Menuitem record. All mutations require explicit staff confirmation via
    # AgentApproval. Attempting to call flag_item_unavailable without a confirmed
    # approval raises Agents::UnauthorisedActionError.
    #
    # Step 1 reads from the PRIMARY DB (not replica) — stale queue state
    # produces bad recommendations.
    #
    # Pipeline (max 4 steps):
    #   1. queue_assess      — read live order queue state from primary DB
    #   2. congestion_reason — rule-based or LLM decision on action type
    #   3. staff_alert       — push recommendation card(s) via ActionCable
    #   4. log_outcome       — write AgentWorkflowRun metadata
    class ServiceOperationsWorkflow
      STEP_NAMES = %w[
        queue_assess
        congestion_reason
        staff_alert
        log_outcome
      ].freeze

      # Action types surfaced to staff dashboards
      ACTION_TYPES = %w[staff_alert item_flag recovery_trigger].freeze

      # Thresholds for rule-based fast path
      LOW_INVENTORY_THRESHOLD   = 2    # currentinventory <= this → 86 suggestion
      CONGESTION_QUEUE_DEPTH    = 8    # concurrent preparing items → congestion card
      CACHE_TTL_SECONDS         = 300  # 5 minutes — recommendation snapshot cache
      QUEUE_BACKLOG_THRESHOLD   = 30   # pending jobs threshold for cache fallback
      LLM_MODEL                 = 'gpt-4o'
      LLM_TEMPERATURE           = 0    # deterministic for ops decisions

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
          unless Flipper.enabled?(:agent_service_operations, @restaurant)
            Rails.logger.info(
              "[ServiceOperationsWorkflow] agent_service_operations flag disabled mid-run " \
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

        @run.reload
        complete_if_finished unless halted
      rescue StandardError => e
        Rails.logger.error(
          "[ServiceOperationsWorkflow] Run #{@run.id} failed: #{e.message}\n" \
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
        when 'queue_assess'      then step_queue_assess
        when 'congestion_reason' then step_congestion_reason
        when 'staff_alert'       then step_staff_alert
        when 'log_outcome'       then step_log_outcome
        else
          raise "Unknown step: #{step.step_name}"
        end
      end

      # -------------------------------------------------------------------------
      # Step 1: queue_assess
      # Read current live order queue from PRIMARY DB (replica latency unacceptable).
      # Returns a snapshot of active orders, per-status item counts, and low-inventory items.
      # -------------------------------------------------------------------------
      def step_queue_assess
        congestion_threshold = @restaurant.kitchen_congestion_threshold
        wait_threshold       = @restaurant.service_operations_wait_threshold_minutes

        active_orders = Ordr
          .where(restaurant_id: @restaurant.id)
          .where.not(status: %w[paid closed cancelled])
          .includes(:ordritems)
          .order(created_at: :asc)

        preparing_count = 0
        long_wait_orders = []
        ordered_count    = 0
        ready_count      = 0
        order_snapshots  = []

        active_orders.each do |ordr|
          items = ordr.ordritems.reject { |i| i.status.to_s == 'removed' }
          item_preparing = items.count { |i| i.status.to_s == 'preparing' }
          item_ordered   = items.count { |i| i.status.to_s == 'ordered' }
          item_ready     = items.count { |i| i.status.to_s == 'ready' }

          preparing_count += item_preparing
          ordered_count   += item_ordered
          ready_count     += item_ready

          # Long-wait: order open longer than threshold with no preparing items yet
          age_minutes = ((Time.current - ordr.created_at) / 60).round
          if age_minutes >= wait_threshold && item_preparing.zero? && item_ordered.positive?
            long_wait_orders << {
              'ordr_id' => ordr.id,
              'table' => ordr.try(:tablesetting)&.name || "Order ##{ordr.id}",
              'elapsed_minutes' => age_minutes,
              'item_count' => items.count,
              'item_names' => items.first(3).map { |i| i.try(:menuitem)&.name || 'Item' },
            }
          end

          order_snapshots << {
            'ordr_id' => ordr.id,
            'status' => ordr.status.to_s,
            'age_minutes' => age_minutes,
          }
        end

        # Low inventory items — menuitems are reached via menusections → menus → restaurant
        menuitem_ids_for_restaurant = Menuitem
          .joins(menusection: :menu)
          .where(menus: { restaurant_id: @restaurant.id })
          .select(:id)

        low_inventory_items = Inventory
          .where(menuitem_id: menuitem_ids_for_restaurant)
          .where(status: :active)
          .where(currentinventory: ..LOW_INVENTORY_THRESHOLD)
          .includes(:menuitem)
          .map do |inv|
            {
              'inventory_id' => inv.id,
              'menuitem_id' => inv.menuitem_id,
              'menuitem_name' => inv.menuitem&.name || 'Unknown',
              'current_stock' => inv.currentinventory,
            }
          end

        congested = preparing_count > congestion_threshold

        {
          'restaurant_id' => @restaurant.id,
          'preparing_count' => preparing_count,
          'ordered_count' => ordered_count,
          'ready_count' => ready_count,
          'active_order_count' => active_orders.count,
          'congested' => congested,
          'congestion_threshold' => congestion_threshold,
          'long_wait_orders' => long_wait_orders,
          'low_inventory_items' => low_inventory_items,
          'trigger_event' => @run.trigger_event,
          'assessed_at' => Time.current.iso8601,
          'order_snapshots' => order_snapshots,
        }
      end

      # -------------------------------------------------------------------------
      # Step 2: congestion_reason
      # Rule-based fast path for simple signals; LLM for complex multi-signal cases.
      # Returns an array of recommendation objects, each with type + payload.
      # -------------------------------------------------------------------------
      def step_congestion_reason
        queue = completed_step_output('queue_assess') || {}
        # --- Rule-based fast paths ---

        # Long-wait detection (always rule-based — deterministic)
        recommendations = Array(queue['long_wait_orders']).map do |wait_order|
          {
            'type' => 'recovery_trigger',
            'ordr_id' => wait_order['ordr_id'],
            'table' => wait_order['table'],
            'elapsed_minutes' => wait_order['elapsed_minutes'],
            'item_count' => wait_order['item_count'],
            'item_names' => wait_order['item_names'],
            'message' => "Table #{wait_order['table']} has been waiting #{wait_order['elapsed_minutes']} min — consider visiting.",
            'suggested_action' => 'Visit table or send apology message',
            'fast_path' => true,
          }
        end

        # Low-inventory 86 suggestions (always rule-based when quantity <= 2)
        Array(queue['low_inventory_items']).each do |item|
          next unless item['current_stock'] <= LOW_INVENTORY_THRESHOLD

          recommendations << {
            'type' => 'item_flag',
            'menuitem_id' => item['menuitem_id'],
            'menuitem_name' => item['menuitem_name'],
            'current_stock' => item['current_stock'],
            'message' => "#{item['menuitem_name']} has #{item['current_stock']} remaining — suggest 86ing.",
            'fast_path' => true,
          }
        end

        # Congestion alert (always rule-based — deterministic threshold check)
        if queue['congested']
          recommendations << {
            'type' => 'staff_alert',
            'preparing_count' => queue['preparing_count'],
            'threshold' => queue['congestion_threshold'],
            'message' => "Kitchen queue: #{queue['preparing_count']} items preparing (threshold: #{queue['congestion_threshold']}). Consider pacing new orders.",
            'fast_path' => true,
          }
        end

        # --- LLM fast path: only for multi-signal or bar-surge situations ---
        if recommendations.empty? && queue.fetch('preparing_count', 0).positive?
          llm_recs = llm_analyse_queue(queue)
          recommendations.concat(llm_recs)
        end

        {
          'recommendations' => recommendations,
          'fast_path_used' => recommendations.all? { |r| r['fast_path'] },
          'recommendation_count' => recommendations.size,
        }
      end

      # -------------------------------------------------------------------------
      # Step 3: staff_alert
      # Push recommendation cards to the relevant dashboard via ActionCable.
      # Creates AgentApproval records for item_flag actions (86 suggestions).
      # -------------------------------------------------------------------------
      def step_staff_alert
        reason   = completed_step_output('congestion_reason') || {}
        recs     = Array(reason['recommendations'])

        cards_pushed = 0
        approvals_created = 0

        recs.each do |rec|
          case rec['type']
          when 'item_flag'
            # Create an AgentApproval for the 86 suggestion — staff must confirm
            step = @run.agent_workflow_steps.find_by(step_name: 'staff_alert')
            approval = create_item_86_approval!(rec, step)
            push_kitchen_card!(rec, approval_id: approval.id)
            approvals_created += 1
            cards_pushed += 1

          when 'recovery_trigger'
            # Push long-wait card to manager via UserChannel — no approval needed (advisory only)
            push_manager_alert!(rec)
            cards_pushed += 1

          when 'staff_alert'
            # Push congestion card to kitchen — no approval needed (advisory only)
            push_kitchen_congestion_card!(rec)
            cards_pushed += 1
          end
        end

        # Update cached recommendation snapshot (5-min TTL)
        update_recommendation_cache!(recs)

        {
          'cards_pushed' => cards_pushed,
          'approvals_created' => approvals_created,
          'pushed_at' => Time.current.iso8601,
        }
      end

      # -------------------------------------------------------------------------
      # Step 4: log_outcome
      # Record lightweight metadata for quality measurement.
      # -------------------------------------------------------------------------
      def step_log_outcome
        alert_output  = completed_step_output('staff_alert') || {}
        reason_output = completed_step_output('congestion_reason') || {}

        {
          'workflow_type' => 'service_operations',
          'restaurant_id' => @restaurant.id,
          'cards_pushed' => alert_output['cards_pushed'].to_i,
          'approvals_created' => alert_output['approvals_created'].to_i,
          'fast_path_used' => reason_output.fetch('fast_path_used', true),
          'recommendation_count' => reason_output.fetch('recommendation_count', 0),
          'logged_at' => Time.current.iso8601,
        }
      end

      # -------------------------------------------------------------------------
      # ActionCable helpers
      # -------------------------------------------------------------------------

      def push_kitchen_card!(rec, approval_id:)
        payload = {
          action: 'agent_recommendation',
          type: 'item_86',
          approval_id: approval_id,
          menuitem_id: rec['menuitem_id'],
          message: rec['message'],
          item_name: rec['menuitem_name'],
          stock: rec['current_stock'],
          timestamp: Time.current.iso8601,
        }
        ActionCable.server.broadcast("kitchen_#{@restaurant.id}", payload)
      end

      def push_manager_alert!(rec)
        # Push to all manager/owner users for this restaurant via UserChannel
        manager_user_ids.each do |uid|
          payload = {
            action: 'agent_recommendation',
            type: 'long_wait',
            ordr_id: rec['ordr_id'],
            table: rec['table'],
            elapsed_minutes: rec['elapsed_minutes'],
            item_count: rec['item_count'],
            item_names: rec['item_names'],
            message: rec['message'],
            suggested_action: rec['suggested_action'],
            timestamp: Time.current.iso8601,
          }
          ActionCable.server.broadcast("user_#{uid}_channel", payload)
        end
      end

      def push_kitchen_congestion_card!(rec)
        payload = {
          action: 'agent_recommendation',
          type: 'congestion',
          preparing_count: rec['preparing_count'],
          threshold: rec['threshold'],
          message: rec['message'],
          timestamp: Time.current.iso8601,
        }
        ActionCable.server.broadcast("kitchen_#{@restaurant.id}", payload)

        # Also push prep time estimate to station channels
        ActionCable.server.broadcast("kitchen_#{@restaurant.id}", payload.merge(action: 'prep_time_estimate'))
        ActionCable.server.broadcast("bar_#{@restaurant.id}", payload.merge(action: 'prep_time_estimate'))
      end

      # -------------------------------------------------------------------------
      # AgentApproval creation for item_86 actions
      # -------------------------------------------------------------------------

      def create_item_86_approval!(rec, step)
        AgentApproval.create!(
          agent_workflow_run: @run,
          agent_workflow_step: step,
          action_type: 'item_86',
          status: 'pending',
          risk_level: 'medium',
          expires_at: 1.hour.from_now,
          idempotency_key: "item_86:#{rec['menuitem_id']}:#{@run.id}",
          proposed_payload: {
            'menuitem_id' => rec['menuitem_id'],
            'menuitem_name' => rec['menuitem_name'],
            'current_stock' => rec['current_stock'],
            'action' => 'set_hidden_true',
          },
        )
      end

      # -------------------------------------------------------------------------
      # Caching
      # -------------------------------------------------------------------------

      def update_recommendation_cache!(recommendations)
        key = "service_ops:#{@restaurant.id}:recommendation_snapshot"
        Rails.cache.write(key, recommendations.to_json, expires_in: CACHE_TTL_SECONDS.seconds)
      rescue StandardError => e
        Rails.logger.warn("[ServiceOperationsWorkflow] Cache write failed: #{e.message}")
      end

      # -------------------------------------------------------------------------
      # LLM reasoning (for complex multi-signal cases only)
      # -------------------------------------------------------------------------

      def llm_analyse_queue(queue)
        system_prompt = <<~PROMPT
          You are a restaurant kitchen operations assistant. Analyse the queue snapshot below.
          Identify if there are any actionable recommendations for staff.
          Only recommend actions if there is a clear signal — do not manufacture recommendations.

          Return ONLY valid JSON with a "recommendations" array.
          Each item: { "type": "staff_alert"|"item_flag"|"recovery_trigger", "message": string }
          If no action is needed, return: { "recommendations": [] }
        PROMPT

        response = openai_client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: queue.to_json },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parsed  = parse_json_from_llm(content)
        Array(parsed['recommendations'])
      rescue StandardError => e
        Rails.logger.warn("[ServiceOperationsWorkflow] LLM analysis failed: #{e.message} — returning empty recommendations")
        []
      end

      # -------------------------------------------------------------------------
      # Helpers
      # -------------------------------------------------------------------------

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

      def manager_user_ids
        Employee
          .where(restaurant: @restaurant, role: %i[manager admin], status: :active)
          .includes(:user)
          .filter_map { |e| e.user&.id }
          .uniq
      rescue StandardError => e
        Rails.logger.warn("[ServiceOperationsWorkflow] manager_user_ids error: #{e.message}")
        []
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
