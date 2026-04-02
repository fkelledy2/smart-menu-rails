# frozen_string_literal: true

module Agents
  # Agents::CustomerConciergeService
  #
  # Synchronous (no background job) concierge for the customer-facing SmartMenu.
  # Receives a natural language query and returns a shortlist of menu items
  # with per-item explanations, respecting allergen filters.
  #
  # Key invariants:
  #   - Allergen exclusion is enforced at the SearchMenuItems tool level in SQL.
  #   - LLM is never given the full allergen logic — it only receives pre-filtered items.
  #   - Session dietary data is read-only; nothing is persisted by this service.
  #   - One lightweight AgentWorkflowRun is created per concierge session for analytics.
  #
  # Usage:
  #   result = Agents::CustomerConciergeService.call(
  #     restaurant:           @restaurant,
  #     smartmenu:            @smartmenu,
  #     query_text:           'I am vegan, what can I eat?',
  #     conversation_history: [],   # array of {role:, content:} hashes, max 5
  #     sessionid:            session[:dining_session_token],
  #     workflow_run_id:      nil,  # pass existing run ID to continue a session
  #   )
  #   # => { items: [...], basket: nil, workflow_run_id: 123, error: nil }
  class CustomerConciergeService
    CANDIDATE_ITEM_LIMIT = 30
    CACHE_TTL            = 15.minutes

    Result = Struct.new(:items, :basket, :workflow_run_id, :error, keyword_init: true)

    def self.call(**kwargs)
      new(**kwargs).call
    end

    def initialize(
      restaurant:,
      smartmenu:,
      query_text:,
      conversation_history: [],
      sessionid: nil,
      workflow_run_id: nil
    )
      @restaurant           = restaurant
      @smartmenu            = smartmenu
      @query_text           = query_text.to_s.strip
      @conversation_history = Array(conversation_history).last(5)
      @sessionid            = sessionid
      @workflow_run_id      = workflow_run_id
    end

    def call
      return error_result('Query cannot be blank') if @query_text.blank?

      run = find_or_create_workflow_run

      # 1. Read customer dietary preferences (allergen IDs to exclude)
      prefs = read_customer_preferences

      # 2. Fetch candidate items from cache or live DB (allergen-filtered in SQL)
      items = fetch_candidate_items(prefs[:excluded_allergyn_ids])

      return error_result('No menu items available') if items.empty?

      # 3. Detect group/basket intent
      basket_intent = detect_basket_intent(@query_text)

      # 4. Build recommendations via LLM
      recommendation_result = compose_recommendations(items, prefs)

      # 5. If basket intent detected, build a basket suggestion
      basket = nil
      if basket_intent[:detected]
        basket = propose_basket(items, basket_intent)
      end

      # 6. Update run analytics (non-blocking)
      update_run_analytics(run, recommendation_result, basket)

      Result.new(
        items: recommendation_result[:items] || [],
        basket: basket,
        workflow_run_id: run&.id,
        error: nil,
      )
    rescue OpenaiClient::RateLimitError, OpenaiClient::ApiError => e
      Rails.logger.error("[CustomerConciergeService] OpenAI error: #{e.class}: #{e.message}")
      update_run_failed(find_run(@workflow_run_id), e.message)
      error_result('Recommendations unavailable right now — browse the menu below')
    rescue StandardError => e
      Rails.logger.error("[CustomerConciergeService] #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
      update_run_failed(find_run(@workflow_run_id), e.message)
      error_result('Recommendations unavailable right now — browse the menu below')
    end

    private

    def read_customer_preferences
      return { locale: 'en', excluded_allergyn_ids: [], has_dietary_restrictions: false } unless @sessionid.present?

      Agents::Tools::ReadCustomerPreferences.call(
        'smartmenu_id' => @smartmenu.id,
        'sessionid'    => @sessionid,
      )
    end

    def fetch_candidate_items(excluded_allergyn_ids)
      cache_key = "concierge:#{@restaurant.id}:#{Digest::MD5.hexdigest(@query_text)}:#{active_menu_version_id}:#{excluded_allergyn_ids.sort.join(',')}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
        result = Agents::Tools::SearchMenuItems.call(
          'restaurant_id'        => @restaurant.id,
          'exclude_allergyn_ids' => excluded_allergyn_ids,
          'limit'                => CANDIDATE_ITEM_LIMIT,
        )
        result[:items] || []
      end
    end

    def compose_recommendations(items, prefs)
      Agents::Tools::ComposeRecommendation.call(
        'items'                => items,
        'query'                => @query_text,
        'locale'               => prefs[:locale] || 'en',
        'currency'             => @restaurant.currency || 'EUR',
        'restaurant_name'      => @restaurant.name,
        'conversation_history' => @conversation_history,
      )
    end

    def propose_basket(items, basket_intent)
      item_ids = items.map { |i| (i[:id] || i['id']).to_i }
      Agents::Tools::ProposeBasket.call(
        'item_ids'   => item_ids,
        'group_size' => basket_intent[:group_size],
        'budget'     => basket_intent[:budget],
      )
    end

    # Simple regex-based intent detection — no LLM call needed.
    def detect_basket_intent(query)
      group_match  = query.match(/\bfor\s+(\d+)\s+(people|persons|guests|of\s+us)\b/i)
      budget_match = query.match(/\bunder\s+[€£$]?\s*(\d+(?:\.\d+)?)\b/i)

      {
        detected:   group_match.present?,
        group_size: group_match ? group_match[1].to_i : 2,
        budget:     budget_match ? budget_match[1].to_f : nil,
      }
    end

    def active_menu_version_id
      @smartmenu.menu&.active_menu_version&.id || 'live'
    rescue StandardError
      'live'
    end

    def find_or_create_workflow_run
      # Reuse run if caller passed one (follow-up query in same session)
      existing = find_run(@workflow_run_id)
      return existing if existing

      AgentWorkflowRun.create!(
        restaurant:     @restaurant,
        workflow_type:  'customer_concierge',
        trigger_event:  'customer_query',
        status:         'running',
        started_at:     Time.current,
        context_snapshot: {
          smartmenu_id: @smartmenu.id,
          sessionid:    @sessionid,
          turn_count:   1,
        },
      )
    rescue StandardError => e
      Rails.logger.warn("[CustomerConciergeService] Could not create AgentWorkflowRun: #{e.message}")
      nil
    end

    def find_run(run_id)
      return nil if run_id.blank?

      AgentWorkflowRun
        .where(restaurant: @restaurant, workflow_type: 'customer_concierge')
        .find_by(id: run_id)
    end

    def update_run_analytics(run, recommendation_result, basket)
      return unless run

      turn_count = (run.context_snapshot&.dig('turn_count') || 0) + 1
      run.update_columns(
        status: 'completed',
        completed_at: Time.current,
        context_snapshot: (run.context_snapshot || {}).merge(
          'item_count_returned' => (recommendation_result[:items] || []).size,
          'basket_proposed'     => basket.present?,
          'turn_count'          => turn_count,
        ),
      )
    rescue StandardError => e
      Rails.logger.warn("[CustomerConciergeService] Could not update run: #{e.message}")
    end

    def update_run_failed(run, message)
      return unless run

      run.update_columns(status: 'failed', completed_at: Time.current,
                          error_message: message.to_s.first(500))
    rescue StandardError
      nil
    end

    def error_result(message)
      Result.new(items: [], basket: nil, workflow_run_id: @workflow_run_id, error: message)
    end
  end
end
