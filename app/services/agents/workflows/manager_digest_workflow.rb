# frozen_string_literal: true

module Agents
  module Workflows
    # Agents::Workflows::ManagerDigestWorkflow orchestrates the 5-step weekly growth
    # digest pipeline. It is invoked by Agents::ManagerDigestWorkflowJob.
    # All analytics reads use the replica DB connection.
    # Digests are advisory-only — no AgentApproval records are created.
    # The workflow never writes to live menu/order models directly.
    #
    # Pipeline:
    #   1. read_performance — tag each menuitem by performance bucket using replica DB
    #   2. growth_reason    — LLM call to identify insights and recommendations
    #   3. copy_draft       — LLM call to generate Instagram + email marketing copy
    #   4. compose_digest   — assemble final digest artifact
    #   5. notify_manager   — persist AgentArtifact, send email, create back-office card
    class ManagerDigestWorkflow
      STEP_NAMES = %w[
        read_performance
        growth_reason
        copy_draft
        compose_digest
        notify_manager
      ].freeze

      # Performance buckets — every item is tagged with one or more.
      PERFORMANCE_BUCKETS = %w[top_mover slow_mover high_margin low_margin high_friction low_friction].freeze

      LLM_MODEL                  = 'gpt-4o'
      LLM_TEMPERATURE_REASON     = 0.3  # balanced for analysis
      LLM_TEMPERATURE_COPY       = 0.7  # creative for marketing copy
      DIGEST_HISTORY_WEEKS       = 8
      MIN_ORDERS_FOR_DIGEST      = 5    # minimum orders in past 7 days for a meaningful digest
      RECENT_ORDERS_WINDOW_DAYS  = 7

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

        STEP_NAMES.each_with_index do |name, idx|
          step = @run.agent_workflow_steps.find_by(step_name: name, step_index: idx)
          next if step.nil? || step.completed? || step.skipped?

          execute_step(step)

          @run.reload
          break if @run.failed?
        end

        @run.reload
        complete_if_finished
      rescue StandardError => e
        Rails.logger.error(
          "[ManagerDigestWorkflow] Run #{@run.id} failed: #{e.message}\n" \
          "#{e.backtrace&.first(5)&.join("\n")}",
        )
        @run.mark_failed!(e.message)
      end

      private

      # Create all 5 step rows up-front so progress is visible immediately.
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
        when 'read_performance' then step_read_performance
        when 'growth_reason'    then step_growth_reason
        when 'copy_draft'       then step_copy_draft
        when 'compose_digest'   then step_compose_digest
        when 'notify_manager'   then step_notify_manager
        else
          raise "Unknown step: #{step.step_name}"
        end
      end

      # ---------------------------------------------------------------------------
      # Step 1: read_performance
      # Aggregate 7-day metrics per item on the replica. Tag each item with
      # one or more performance buckets.
      # ---------------------------------------------------------------------------
      def step_read_performance
        tagged_items = ApplicationRecord.connected_to(role: :reading) do
          build_tagged_items
        end

        {
          restaurant_id: @restaurant.id,
          restaurant_name: @restaurant.name,
          establishment_type: @restaurant.try(:establishment_type) || 'restaurant',
          window_days: RECENT_ORDERS_WINDOW_DAYS,
          tagged_items: tagged_items,
          total_items: tagged_items.size,
        }
      end

      # ---------------------------------------------------------------------------
      # Step 2: growth_reason
      # LLM call to identify top performers, underperformers, repricing candidates,
      # and friction items. Returns a structured JSON change set.
      # ---------------------------------------------------------------------------
      def step_growth_reason
        perf = completed_step_output('read_performance') || {}
        tagged_items = perf['tagged_items'] || []

        return fallback_growth_reason(perf) if tagged_items.empty?

        system_prompt = <<~PROMPT
          You are a restaurant business advisor. Analyse the 7-day item performance data below.
          Identify:
          1. Top 5 items by revenue/order count ("top_performers" list)
          2. Bottom 5 items that underperform with a suggested action per item:
             remove | reprice | reimage | promote ("underperformers" list — each must have "action" key)
          3. Up to 3 repricing candidates: items with high conversion but low margin ("repricing_candidates")
          4. Up to 3 friction items: high browse rate but low order conversion ("friction_items")
          5. One "weekend_recommendation": a short actionable suggestion for the upcoming weekend service

          Return ONLY valid JSON with keys:
          top_performers, underperformers, repricing_candidates, friction_items, weekend_recommendation
          Each item in a list: { "menuitem_id", "name", "action" (where applicable), "reason" }
          weekend_recommendation: plain string.
        PROMPT

        response = openai_client.chat_with_tools(
          model: LLM_MODEL,
          messages: [
            { role: 'system', content: system_prompt },
            { role: 'user', content: tagged_items.to_json },
          ],
          tools: [],
          temperature: LLM_TEMPERATURE_REASON,
        )

        content = response.dig('choices', 0, 'message', 'content').to_s
        parsed  = parse_json_from_llm(content)

        {
          top_performers: Array(parsed['top_performers']),
          underperformers: Array(parsed['underperformers']),
          repricing_candidates: Array(parsed['repricing_candidates']),
          friction_items: Array(parsed['friction_items']),
          weekend_recommendation: parsed['weekend_recommendation'].to_s,
        }
      rescue JSON::ParserError => e
        Rails.logger.warn("[ManagerDigestWorkflow] growth_reason JSON parse error: #{e.message}")
        fallback_growth_reason(perf)
      end

      # ---------------------------------------------------------------------------
      # Step 3: copy_draft
      # Generate Instagram + email marketing copy for the top-margin featured item.
      # ---------------------------------------------------------------------------
      def step_copy_draft
        perf = completed_step_output('read_performance') || {}
        tagged_items = perf['tagged_items'] || []

        # Pick the highest-margin item from high_margin bucket, falling back to top_mover
        featured = tagged_items.find { |i| i['buckets']&.include?('high_margin') }
        featured ||= tagged_items.find { |i| i['buckets']&.include?('top_mover') }
        featured ||= tagged_items.first

        return { instagram_caption: '', email_body: '', featured_item: nil } unless featured

        copy_result = Agents::Tools::DraftMarketingCopy.call(
          'item_name' => featured['name'].to_s,
          'item_description' => featured['description'].to_s,
          'restaurant_name' => @restaurant.name,
          'establishment_type' => perf['establishment_type'] || 'restaurant',
          'tone' => 'warm',
        )

        {
          instagram_caption: copy_result[:instagram_caption],
          email_body: copy_result[:email_body],
          featured_item: {
            menuitem_id: featured['menuitem_id'],
            name: featured['name'],
          },
        }
      end

      # ---------------------------------------------------------------------------
      # Step 4: compose_digest
      # Assemble the final digest narrative using ComposeManagerSummary tool.
      # ---------------------------------------------------------------------------
      def step_compose_digest
        perf   = completed_step_output('read_performance') || {}
        reason = completed_step_output('growth_reason')    || {}
        copy   = completed_step_output('copy_draft')       || {}

        context = {
          restaurant: @restaurant.name,
          window_days: perf['window_days'],
          total_items: perf['total_items'],
          top_performers: reason['top_performers'],
          underperformers: reason['underperformers'],
          repricing_candidates: reason['repricing_candidates'],
          friction_items: reason['friction_items'],
          weekend_recommendation: reason['weekend_recommendation'],
        }

        summary_result = Agents::Tools::ComposeManagerSummary.call(
          'context' => context,
          'tone' => 'casual',
        )

        {
          narrative: summary_result[:summary] || summary_result['summary'] || '',
          insights: build_insight_list(reason),
          marketing_copy: {
            instagram_caption: copy['instagram_caption'],
            email_body: copy['email_body'],
            featured_item: copy['featured_item'],
          },
          weekend_recommendation: reason['weekend_recommendation'],
          generated_at: Time.current.iso8601,
        }
      end

      # ---------------------------------------------------------------------------
      # Step 5: notify_manager
      # Persist approved AgentArtifact, send digest email, create back-office card.
      # Growth digests are auto_approved — no AgentApproval records needed.
      # ---------------------------------------------------------------------------
      def step_notify_manager
        digest_output = completed_step_output('compose_digest') || {}

        digest_content = {
          restaurant_id: @restaurant.id,
          narrative: digest_output['narrative'],
          insights: digest_output['insights'],
          marketing_copy: digest_output['marketing_copy'],
          weekend_recommendation: digest_output['weekend_recommendation'],
          generated_at: digest_output['generated_at'],
          performance_window_days: RECENT_ORDERS_WINDOW_DAYS,
        }

        result = Agents::ArtifactWriter.call(
          workflow_run: @run,
          artifact_type: 'growth_digest',
          content: digest_content,
        )

        raise "ArtifactWriter failed: #{result.error}" unless result.success?

        # Mark artifact as approved (advisory — no human gate)
        result.artifact.update_column(:status, 'approved')

        # Send email to all managers and owners for this restaurant
        recipients = managers_and_owners
        recipients.each do |user|
          AgentDigestMailer.weekly_digest(@restaurant, result.artifact, user).deliver_later
        end

        {
          artifact_id: result.artifact.id,
          emails_sent: recipients.size,
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

      # Build tagged items hash from Ordritem + Menuitem + ProfitMarginAnalyticsService data.
      # Uses replica DB — caller must wrap in connected_to(role: :reading).
      def build_tagged_items
        since = RECENT_ORDERS_WINDOW_DAYS.days.ago

        # 1. Order-count aggregation by menuitem
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

        # 2. Load active menuitems with cost data
        menuitems = @restaurant.menus
          .includes(menusections: { menuitems: [:menuitem_costs] })
          .flat_map { |menu| menu.menusections.flat_map(&:menuitems) }
          .select { |mi| mi.respond_to?(:status) && mi.status.to_s == 'active' }
          .uniq(&:id)

        median_orders = compute_median(order_counts.values.pluck(:order_count))

        menuitems.map do |mi|
          counts     = order_counts[mi.id] || { order_count: 0, quantity: 0 }
          order_cnt  = counts[:order_count]
          margin_pct = mi.respond_to?(:profit_margin_percentage) ? mi.profit_margin_percentage.to_f : 0.0
          order_share = total_orders.positive? ? (order_cnt.to_f / total_orders) : 0.0

          buckets = compute_buckets(
            order_cnt: order_cnt,
            median_orders: median_orders,
            margin_pct: margin_pct,
            order_share: order_share,
          )

          {
            'menuitem_id' => mi.id,
            'name' => mi.name,
            'description' => mi.try(:description).to_s,
            'price' => mi.try(:price).to_f,
            'order_count' => order_cnt,
            'order_share' => order_share.round(4),
            'margin_pct' => margin_pct,
            'buckets' => buckets,
          }
        end
      end

      def compute_buckets(order_cnt:, median_orders:, margin_pct:, order_share:)
        buckets = []

        buckets << 'top_mover'  if order_cnt.positive? && order_cnt >= [median_orders * 1.5, 1].max
        buckets << 'slow_mover' if order_cnt < [median_orders * 0.5, 1].min || order_cnt.zero?
        buckets << 'high_margin' if margin_pct >= 60.0
        buckets << 'low_margin'  if margin_pct.positive? && margin_pct < 30.0
        # high_friction: browsed often but rarely ordered (approximate via low order_share despite existing)
        buckets << 'high_friction' if order_share < 0.05 && order_cnt.zero?
        buckets << 'low_friction'  if order_share >= 0.15

        buckets.uniq
      end

      def compute_median(values)
        return 0 if values.empty?

        sorted = values.sort
        mid    = sorted.size / 2
        sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
      end

      def build_insight_list(reason)
        insights = Array(reason['top_performers']).map do |item|
          {
            type: 'top_performer',
            menuitem_id: item['menuitem_id'],
            name: item['name'],
            reason: item['reason'],
            action: nil,
            action_url: nil,
          }
        end

        Array(reason['underperformers']).each do |item|
          insights << {
            type: 'underperformer',
            menuitem_id: item['menuitem_id'],
            name: item['name'],
            reason: item['reason'],
            action: item['action'],
            action_url: nil, # populated in view from menuitem_id
          }
        end

        Array(reason['repricing_candidates']).each do |item|
          insights << {
            type: 'repricing_candidate',
            menuitem_id: item['menuitem_id'],
            name: item['name'],
            reason: item['reason'],
            action: 'reprice',
            action_url: nil,
          }
        end

        Array(reason['friction_items']).each do |item|
          insights << {
            type: 'friction',
            menuitem_id: item['menuitem_id'],
            name: item['name'],
            reason: item['reason'],
            action: 'review',
            action_url: nil,
          }
        end

        insights
      end

      def managers_and_owners
        Employee
          .where(restaurant: @restaurant, role: %i[manager admin], status: :active)
          .includes(:user)
          .filter_map(&:user)
          .uniq(&:id)
      end

      # Fallback when LLM returns invalid JSON — uses raw performance data.
      def fallback_growth_reason(perf)
        tagged_items = Array(perf['tagged_items'])
        top    = tagged_items.select { |i| i['buckets']&.include?('top_mover') }.first(5)
        bottom = tagged_items.select { |i| i['buckets']&.include?('slow_mover') }.first(5)

        {
          top_performers: top.map { |i| { 'menuitem_id' => i['menuitem_id'], 'name' => i['name'], 'reason' => 'High order volume' } },
          underperformers: bottom.map { |i| { 'menuitem_id' => i['menuitem_id'], 'name' => i['name'], 'action' => 'review', 'reason' => 'Low order volume' } },
          repricing_candidates: [],
          friction_items: [],
          weekend_recommendation: 'Review slow movers and consider running a special for the weekend.',
          fallback: true,
        }
      end

      # Extract JSON from an LLM response that may have markdown fences or surrounding text.
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
