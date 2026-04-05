# frozen_string_literal: true

module Agents
  # Agents::StaffCopilotService — synchronous natural-language back-office assistant.
  #
  # Accepts a plain-text query from a restaurant staff member and returns a
  # CopilotResponse value object that the controller renders as a Turbo Stream.
  #
  # WRITE SAFETY CONTRACT:
  #   - This service never writes directly to the database.
  #   - Write actions produce an action_card payload; execution only happens after
  #     the user clicks "Confirm" on the separate /copilot/confirm endpoint.
  #   - Pundit policies are checked before any tool is invoked.
  #
  # Usage:
  #   result = Agents::StaffCopilotService.call(
  #     restaurant:           @restaurant,
  #     user:                 current_user,
  #     query_text:           'eighty-six the burrata',
  #     conversation_history: [...],  # max 5 turns from browser session
  #     page_context:         '/restaurants/42/menus',
  #   )
  #   result.response_type   # => :narrative | :action_card | :disambiguation | :error
  #   result.narrative_text  # => String (nil for action_card)
  #   result.action_card     # => Hash (nil for narrative)
  class StaffCopilotService
    LLM_MODEL           = 'gpt-4o'
    MAX_HISTORY_TURNS   = 5
    RATE_LIMIT_COUNT    = 30
    RATE_LIMIT_WINDOW   = 1.hour.to_i

    INTENT_TYPES = %w[
      analytics_query
      item_availability
      new_item
      menu_edit
      staff_message
      report_request
      unknown
    ].freeze

    # Value object returned to the controller.
    CopilotResponse = Struct.new(
      :response_type,     # Symbol: :narrative | :action_card | :disambiguation | :error
      :narrative_text,    # String — rendered for narrative/error responses
      :action_card,       # Hash  — rendered for action_card responses
      :disambiguation,    # Array of hashes — rendered for disambiguation responses
      :intent_type,       # String — logged for analytics
      :tool_called,       # String — logged for analytics
      keyword_init: true,
    )

    def self.call(**)
      new(**).call
    end

    def initialize(restaurant:, user:, query_text:, conversation_history: [], page_context: nil)
      @restaurant           = restaurant
      @user                 = user
      @query_text           = query_text.to_s.strip
      @conversation_history = Array(conversation_history).last(MAX_HISTORY_TURNS)
      @page_context         = page_context.to_s
    end

    def call
      return rate_limited_response if rate_limited?

      if @query_text.blank?
        return CopilotResponse.new(
          response_type: :error,
          narrative_text: 'Please enter a message.',
          intent_type: 'unknown',
          tool_called: nil,
        )
      end

      classified = classify_intent
      intent     = classified[:intent]
      entities   = classified[:entities] || {}

      result = dispatch_intent(intent, entities)
      log_run(intent, result)
      result
    rescue StandardError => e
      Rails.logger.error("[StaffCopilotService] Error for restaurant #{@restaurant.id}: #{e.message}\n#{e.backtrace&.first(3)&.join("\n")}")
      CopilotResponse.new(
        response_type: :error,
        narrative_text: 'Something went wrong. Please try again.',
        intent_type: 'unknown',
        tool_called: nil,
      )
    end

    private

    # --------------------------------------------------------------------------
    # Rate limiting (Redis counter per user per hour)
    # --------------------------------------------------------------------------

    def rate_limited?
      # Use Rails.cache to store a counter scoped to user + hourly bucket.
      # increment returns the new value (or raises if the store is unavailable).
      bucket_key = "copilot:rate:#{@user.id}:#{Time.current.to_i / RATE_LIMIT_WINDOW}"
      count = Rails.cache.increment(bucket_key, 1, expires_in: RATE_LIMIT_WINDOW)
      count > RATE_LIMIT_COUNT
    rescue StandardError
      # If cache is down, fail open (don't block the user)
      false
    end

    def rate_limited_response
      CopilotResponse.new(
        response_type: :error,
        narrative_text: "You've reached the limit of #{RATE_LIMIT_COUNT} copilot queries per hour. Please try again later.",
        intent_type: 'rate_limited',
        tool_called: nil,
      )
    end

    # --------------------------------------------------------------------------
    # Intent classification via LLM
    # --------------------------------------------------------------------------

    def classify_intent
      system_prompt = classification_system_prompt
      user_message  = build_classification_user_message

      response = openai_client.chat_with_tools(
        model: LLM_MODEL,
        messages: [
          { role: 'system', content: system_prompt },
          *history_messages,
          { role: 'user', content: user_message },
        ],
        tools: [],
        temperature: 0.0,
      )

      content = response.dig('choices', 0, 'message', 'content').to_s
      parse_classification(content)
    rescue StandardError => e
      Rails.logger.warn("[StaffCopilotService] Classification failed: #{e.message}")
      { intent: 'unknown', entities: {} }
    end

    def classification_system_prompt
      <<~PROMPT
        You are a classification assistant for the mellow.menu restaurant management platform.
        Your task is to classify the staff member's query into one of these intents:
          - analytics_query: staff wants to see data, reports, best-sellers, margins, revenue, covers, etc.
          - item_availability: staff wants to mark an item as unavailable/available (e.g., "86 the burrata", "bring back the salmon")
          - new_item: staff wants to create a new menu item or special
          - menu_edit: staff wants to change the name, price, or description of an existing item
          - staff_message: staff wants to draft or send an internal team message/briefing
          - report_request: staff wants a specific formatted report (revenue summary, shift summary, etc.)
          - unknown: cannot classify

        Also extract any key entities:
          - item_name: the name of the menu item referenced (string or null)
          - item_price: price if mentioned (number or null)
          - item_allergens: allergens mentioned as array of strings (e.g., ["fish", "gluten"])
          - item_description: description if provided
          - period: time period for analytics (e.g., "last week", "today", "this month") or null
          - availability_action: "hide" or "show" for item_availability intents
          - message_topic: topic/subject for staff_message intents

        Reply ONLY with a JSON object in this exact format (no markdown, no extra text):
        {"intent":"<intent>","entities":{"item_name":null,"item_price":null,"item_allergens":[],"item_description":null,"period":null,"availability_action":null,"message_topic":null}}
      PROMPT
    end

    def build_classification_user_message
      context = @page_context.present? ? "Current page: #{@page_context}. " : ''
      "#{context}Query: #{@query_text}"
    end

    def history_messages
      @conversation_history.flat_map do |turn|
        messages = []
        messages << { role: 'user', content: turn['query'] } if turn['query'].present?
        messages << { role: 'assistant', content: turn['response'] } if turn['response'].present?
        messages
      end
    end

    def parse_classification(content)
      json = JSON.parse(content.strip)
      intent = json['intent'].to_s
      intent = 'unknown' unless INTENT_TYPES.include?(intent)
      { intent: intent, entities: json.fetch('entities', {}) }
    rescue JSON::ParserError
      { intent: 'unknown', entities: {} }
    end

    # --------------------------------------------------------------------------
    # Intent dispatch
    # --------------------------------------------------------------------------

    def dispatch_intent(intent, entities)
      case intent
      when 'analytics_query', 'report_request'
        handle_analytics_query(entities)
      when 'item_availability'
        handle_item_availability(entities)
      when 'new_item'
        handle_new_item(entities)
      when 'menu_edit'
        handle_menu_edit(entities)
      when 'staff_message'
        handle_staff_message(entities)
      else
        CopilotResponse.new(
          response_type: :narrative,
          narrative_text: 'I can help with: menu changes, item availability, analytics reports, and team messages. What would you like to do?',
          intent_type: intent,
          tool_called: nil,
        )
      end
    end

    # --------------------------------------------------------------------------
    # Analytics handler (read-only, no confirmation required)
    # --------------------------------------------------------------------------

    def handle_analytics_query(entities)
      period    = entities['period'] || 'last week'
      item_name = entities['item_name']

      data = read_order_analytics(period: period, item_name: item_name)

      narrative = format_analytics_narrative(data, period)

      CopilotResponse.new(
        response_type: :narrative,
        narrative_text: narrative,
        intent_type: 'analytics_query',
        tool_called: 'read_order_analytics',
      )
    rescue StandardError => e
      Rails.logger.warn("[StaffCopilotService] Analytics query failed: #{e.message}")
      CopilotResponse.new(
        response_type: :narrative,
        narrative_text: 'Unable to fetch analytics at this time. Please try again or visit the Analytics page.',
        intent_type: 'analytics_query',
        tool_called: 'read_order_analytics',
      )
    end

    # --------------------------------------------------------------------------
    # Item availability handler
    # --------------------------------------------------------------------------

    def handle_item_availability(entities)
      item_name  = entities['item_name'].to_s.strip
      action     = entities['availability_action'].to_s # 'hide' or 'show'

      if item_name.blank?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: 'Which item would you like to update?',
          intent_type: 'item_availability',
          tool_called: nil,
        )
      end

      matches = find_menu_items(item_name)

      if matches.empty?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "I couldn't find \"#{item_name}\" on your menu. Please check the name and try again.",
          intent_type: 'item_availability',
          tool_called: 'search_menu_items',
        )
      end

      # Disambiguation: multiple matches
      if matches.size > 1
        return CopilotResponse.new(
          response_type: :disambiguation,
          narrative_text: "I found #{matches.size} items matching \"#{item_name}\". Which one did you mean?",
          disambiguation: matches.map do |m|
            {
              id: m[:id],
              name: m[:name],
              price: m[:price],
              section: m[:section_name],
              action: action.presence || 'hide',
            }
          end,
          intent_type: 'item_availability',
          tool_called: 'search_menu_items',
        )
      end

      item       = matches.first
      hide_item  = action != 'show'
      new_status = hide_item ? 'unavailable' : 'available'
      verb       = hide_item ? 'Mark as unavailable (86)' : 'Mark as available'

      # Pundit check: caller must have permission to edit this menuitem
      unless user_can_toggle_availability?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "You don't have permission to change item availability.",
          intent_type: 'item_availability',
          tool_called: nil,
        )
      end

      CopilotResponse.new(
        response_type: :action_card,
        action_card: {
          tool_name: 'flag_item_unavailable',
          title: "#{verb}: #{item[:name]}",
          preview: "#{item[:name]} (#{item[:section_name]}) will be set to #{new_status}.",
          confirm_params: {
            tool_name: 'flag_item_unavailable',
            menuitem_id: item[:id],
            hide: hide_item,
          },
        },
        intent_type: 'item_availability',
        tool_called: 'flag_item_unavailable',
      )
    end

    # --------------------------------------------------------------------------
    # New item handler
    # --------------------------------------------------------------------------

    def handle_new_item(entities)
      unless user_can_create_menu_items?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "You don't have permission to add menu items.",
          intent_type: 'new_item',
          tool_called: nil,
        )
      end

      item_name    = entities['item_name'].to_s.strip
      item_price   = entities['item_price']
      allergens    = Array(entities['item_allergens'])
      description  = entities['item_description'].to_s.strip

      if item_name.blank?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: 'What should the new item be called? Please include the name and price.',
          intent_type: 'new_item',
          tool_called: nil,
        )
      end

      # Find the first active menu's first section as default placement
      default_section = default_menu_section

      preview_lines = ["Name: #{item_name}"]
      preview_lines << "Price: #{format_price(item_price)}" if item_price.present?
      preview_lines << "Description: #{description}" if description.present?
      preview_lines << "Allergens: #{allergens.join(', ')}" if allergens.any?
      preview_lines << "Section: #{default_section&.dig(:name) || 'First section on live menu'}"

      CopilotResponse.new(
        response_type: :action_card,
        action_card: {
          tool_name: 'create_menu_item',
          title: "Create new item: #{item_name}",
          preview: preview_lines.join("\n"),
          confirm_params: {
            tool_name: 'create_menu_item',
            name: item_name,
            price_cents: price_to_cents(item_price),
            description: description,
            allergen_names: allergens,
            menusection_id: default_section&.dig(:id),
          },
        },
        intent_type: 'new_item',
        tool_called: 'create_menu_item',
      )
    end

    # --------------------------------------------------------------------------
    # Menu edit handler (name/description changes only — price requires manager)
    # --------------------------------------------------------------------------

    def handle_menu_edit(entities)
      item_name = entities['item_name'].to_s.strip
      new_price = entities['item_price']

      # Waiters cannot change prices
      if new_price.present? && !user_can_edit_prices?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "You don't have permission to change item prices.",
          intent_type: 'menu_edit',
          tool_called: nil,
        )
      end

      unless user_can_edit_menu_items?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "You don't have permission to edit menu items.",
          intent_type: 'menu_edit',
          tool_called: nil,
        )
      end

      if item_name.blank?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: 'Which item would you like to edit? Please include the item name.',
          intent_type: 'menu_edit',
          tool_called: nil,
        )
      end

      matches = find_menu_items(item_name)

      if matches.empty?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "I couldn't find \"#{item_name}\" on your menu.",
          intent_type: 'menu_edit',
          tool_called: 'search_menu_items',
        )
      end

      if matches.size > 1
        return CopilotResponse.new(
          response_type: :disambiguation,
          narrative_text: "I found #{matches.size} items matching \"#{item_name}\". Which one did you mean?",
          disambiguation: matches.map do |m|
            {
              id: m[:id],
              name: m[:name],
              price: m[:price],
              section: m[:section_name],
              action: 'edit',
            }
          end,
          intent_type: 'menu_edit',
          tool_called: 'search_menu_items',
        )
      end

      item        = matches.first
      description = entities['item_description'].to_s.strip

      changes = {}
      changes[:price_cents] = price_to_cents(new_price) if new_price.present?
      changes[:description] = description if description.present?

      if changes.empty?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "What changes would you like to make to #{item[:name]}? (e.g., new description or price)",
          intent_type: 'menu_edit',
          tool_called: nil,
        )
      end

      preview_lines = ["Update: #{item[:name]}"]
      preview_lines << "New price: #{format_price(new_price)}" if changes[:price_cents]
      preview_lines << "New description: #{description}" if changes[:description]

      CopilotResponse.new(
        response_type: :action_card,
        action_card: {
          tool_name: 'update_menu_item',
          title: "Edit: #{item[:name]}",
          preview: preview_lines.join("\n"),
          confirm_params: {
            tool_name: 'update_menu_item',
            menuitem_id: item[:id],
            **changes,
          },
        },
        intent_type: 'menu_edit',
        tool_called: 'update_menu_item',
      )
    end

    # --------------------------------------------------------------------------
    # Staff message handler
    # --------------------------------------------------------------------------

    def handle_staff_message(entities)
      unless user_can_send_staff_messages?
        return CopilotResponse.new(
          response_type: :narrative,
          narrative_text: "You don't have permission to send staff messages.",
          intent_type: 'staff_message',
          tool_called: nil,
        )
      end

      topic = entities['message_topic'].to_s.strip
      topic = @query_text if topic.blank?

      draft = draft_staff_message(topic: topic)

      CopilotResponse.new(
        response_type: :action_card,
        action_card: {
          tool_name: 'send_staff_message',
          title: 'Send team message',
          preview: draft[:body],
          editable: true,
          confirm_params: {
            tool_name: 'send_staff_message',
            subject: draft[:subject],
            body: draft[:body],
          },
        },
        intent_type: 'staff_message',
        tool_called: 'draft_staff_message',
      )
    end

    # --------------------------------------------------------------------------
    # Helpers — data access
    # --------------------------------------------------------------------------

    def read_order_analytics(period:, item_name: nil)
      Agents::Tools::ReadOrderAnalytics.call(
        'restaurant_id' => @restaurant.id,
        'period' => period,
        'item_name' => item_name,
      )
    end

    def find_menu_items(name_query)
      result = Agents::Tools::SearchMenuItems.call(
        'restaurant_id' => @restaurant.id,
        'query' => name_query,
        'limit' => 5,
      )

      items_with_sections = result[:items] || []

      # Enrich with section names
      section_ids = items_with_sections.pluck(:section_id).uniq.compact
      sections = Menusection.where(id: section_ids).pluck(:id, :name).to_h

      items_with_sections.map do |item|
        item.merge(section_name: sections[item[:section_id]] || 'Unknown section')
      end
    end

    def default_menu_section
      section = Menusection
        .joins(:menu)
        .where(menus: { restaurant_id: @restaurant.id, archived: false })
        .where(menus: { status: 'active' })
        .order('menus.created_at ASC, menusections.sequence ASC')
        .limit(1)
        .first

      return nil unless section

      { id: section.id, name: section.name }
    end

    def draft_staff_message(topic:)
      Agents::Tools::DraftStaffMessage.call(
        'restaurant_name' => @restaurant.name,
        'topic' => topic,
      )
    end

    def format_analytics_narrative(data, period)
      return 'No order data available for the selected period.' if data[:orders].blank?

      lines = ["Analytics for #{@restaurant.name} — #{period.capitalize}:"]
      lines << "  Total orders: #{data[:total_orders]}"
      lines << "  Total revenue: #{data[:total_revenue_formatted]}" if data[:total_revenue_formatted]
      lines << "  Average ticket: #{data[:avg_ticket_formatted]}" if data[:avg_ticket_formatted]

      if data[:top_items]&.any?
        lines << ''
        lines << 'Top items by quantity:'
        data[:top_items].first(5).each_with_index do |item, i|
          margin = item[:margin_pct] ? " (margin: #{item[:margin_pct]}%)" : ''
          lines << "  #{i + 1}. #{item[:name]} — #{item[:quantity_sold]} sold#{margin}"
        end
      end

      lines.join("\n")
    end

    def format_price(price)
      return 'unspecified' if price.nil?

      symbol = @restaurant.respond_to?(:currency_symbol) ? @restaurant.currency_symbol : '€'
      "#{symbol}#{format('%.2f', price.to_f)}"
    end

    def price_to_cents(price)
      return nil if price.nil?

      (price.to_f * 100).round
    end

    # --------------------------------------------------------------------------
    # Pundit-equivalent role checks
    # --------------------------------------------------------------------------

    def user_role
      return :owner if @restaurant.user_id == @user.id

      employee = @user.employees.find_by(restaurant_id: @restaurant.id)
      return :none unless employee&.active?

      employee.role.to_sym
    end

    def owner_or_manager?
      %i[owner manager admin].include?(user_role)
    end

    def user_can_toggle_availability?
      %i[owner manager admin staff].include?(user_role)
    end

    def user_can_create_menu_items?
      owner_or_manager?
    end

    def user_can_edit_menu_items?
      owner_or_manager?
    end

    def user_can_edit_prices?
      owner_or_manager?
    end

    def user_can_send_staff_messages?
      owner_or_manager?
    end

    # --------------------------------------------------------------------------
    # Analytics logging
    # --------------------------------------------------------------------------

    def log_run(intent, result)
      AgentWorkflowRun.create!(
        restaurant: @restaurant,
        workflow_type: 'staff_copilot',
        trigger_event: 'copilot.query',
        status: 'completed',
        started_at: Time.current,
        completed_at: Time.current,
        context_snapshot: {
          user_id: @user.id,
          intent_type: intent,
          tool_called: result.tool_called,
          query_length: @query_text.length,
        },
      )
    rescue StandardError => e
      # Logging must never break the response
      Rails.logger.warn("[StaffCopilotService] Failed to log run: #{e.message}")
    end

    def openai_client
      @openai_client ||= OpenaiClient.new
    end
  end
end
