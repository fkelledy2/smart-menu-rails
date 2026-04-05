# frozen_string_literal: true

require 'test_helper'

class Agents::StaffCopilotServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @owner      = users(:one)
    @manager    = users(:two)

    # Ensure Flipper flags are on
    Flipper.enable(:agent_framework)
    Flipper.enable(:agent_staff_copilot, @restaurant)

    # Clear cached rate-limit keys
    Rails.cache.clear
  end

  def teardown
    Flipper.disable(:agent_framework)
    Flipper.disable(:agent_staff_copilot)
    AgentWorkflowRun.where(workflow_type: 'staff_copilot', restaurant: @restaurant).destroy_all
    Rails.cache.clear
  end

  # ---------------------------------------------------------------------------
  # Blank query
  # ---------------------------------------------------------------------------

  test 'returns error response when query is blank' do
    result = call_service(query_text: '')
    assert_equal :error, result.response_type
    assert_match(/enter a message/i, result.narrative_text)
    assert_equal 'unknown', result.intent_type
  end

  test 'returns error response when query is whitespace only' do
    result = call_service(query_text: '   ')
    assert_equal :error, result.response_type
  end

  # ---------------------------------------------------------------------------
  # Rate limiting
  # ---------------------------------------------------------------------------

  test 'returns error after exceeding rate limit' do
    # Simulate the counter already at the limit
    bucket_key = "copilot:rate:#{@owner.id}:#{Time.current.to_i / Agents::StaffCopilotService::RATE_LIMIT_WINDOW}"
    Rails.cache.write(bucket_key, Agents::StaffCopilotService::RATE_LIMIT_COUNT + 1)

    result = call_service(query_text: 'show me sales')
    assert_equal :error, result.response_type
    assert_match(/limit/i, result.narrative_text)
    assert_equal 'rate_limited', result.intent_type
  end

  # ---------------------------------------------------------------------------
  # Unknown intent fallback
  # ---------------------------------------------------------------------------

  test 'returns narrative for unknown intent' do
    stub_classification(intent: 'unknown') do
      result = call_service(query_text: 'bleep bloop')
      assert_equal :narrative, result.response_type
      assert_match(/I can help with/i, result.narrative_text)
    end
  end

  # ---------------------------------------------------------------------------
  # Analytics query
  # ---------------------------------------------------------------------------

  test 'handles analytics_query intent and returns narrative' do
    stub_classification(intent: 'analytics_query', entities: { 'period' => 'last week' }) do
      stub_analytics_tool do
        result = call_service(query_text: 'show me last week best sellers')
        assert_equal :narrative, result.response_type
        assert_equal 'analytics_query', result.intent_type
        assert_equal 'read_order_analytics', result.tool_called
      end
    end
  end

  test 'returns fallback narrative when analytics tool fails' do
    stub_classification(intent: 'analytics_query') do
      Agents::Tools::ReadOrderAnalytics.stub(:call, ->(_p) { raise 'DB error' }) do
        result = call_service(query_text: 'show me revenue')
        assert_equal :narrative, result.response_type
        assert_match(/unable to fetch/i, result.narrative_text)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Item availability — action card
  # ---------------------------------------------------------------------------

  test 'returns action card for item availability when item is found' do
    stub_classification(intent: 'item_availability', entities: { 'item_name' => 'Zucchini Flan', 'availability_action' => 'hide' }) do
      stub_search_tool([{ id: menuitems(:one).id, name: 'Zucchini Flan', price: 12.5, section_id: menusections(:one).id }]) do
        result = call_service(query_text: '86 the zucchini flan')
        assert_equal :action_card, result.response_type
        assert_equal 'flag_item_unavailable', result.action_card[:tool_name]
        assert result.action_card[:confirm_params][:menuitem_id].present?
        assert_equal 'item_availability', result.intent_type
      end
    end
  end

  test 'returns narrative when item not found' do
    stub_classification(intent: 'item_availability', entities: { 'item_name' => 'Nonexistent Dish' }) do
      stub_search_tool([]) do
        result = call_service(query_text: '86 the nonexistent dish')
        assert_equal :narrative, result.response_type
        assert_match(/couldn't find/i, result.narrative_text)
      end
    end
  end

  test 'returns disambiguation when multiple items match' do
    items = [
      { id: 1, name: 'Chicken Wings', price: 12.0, section_id: 1 },
      { id: 2, name: 'Chicken Burger', price: 14.0, section_id: 1 },
    ]
    stub_classification(intent: 'item_availability', entities: { 'item_name' => 'Chicken' }) do
      stub_search_tool(items) do
        result = call_service(query_text: '86 the chicken')
        assert_equal :disambiguation, result.response_type
        assert_equal 2, result.disambiguation.size
      end
    end
  end

  test 'returns permission error for availability when user is not staff of restaurant' do
    other_user = users(:two)  # owner of restaurant :two, no access to restaurant :one
    stub_classification(intent: 'item_availability', entities: { 'item_name' => 'Zucchini Flan', 'availability_action' => 'hide' }) do
      stub_search_tool([{ id: 1, name: 'Zucchini Flan', price: 12.5, section_id: 1 }]) do
        result = call_service(query_text: '86 the zucchini flan', user: other_user)
        assert_equal :narrative, result.response_type
        assert_match(/permission/i, result.narrative_text)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # New item
  # ---------------------------------------------------------------------------

  test 'returns action card for new item when user is manager' do
    stub_classification(intent: 'new_item', entities: {
      'item_name'        => 'Grilled Salmon',
      'item_price'       => 28.0,
      'item_allergens'   => %w[fish gluten],
      'item_description' => 'Fresh Atlantic salmon',
    }) do
      result = call_service(query_text: 'add grilled salmon €28')
      assert_equal :action_card, result.response_type
      assert_equal 'create_menu_item', result.action_card[:tool_name]
      assert_equal 'Grilled Salmon', result.action_card[:confirm_params][:name]
    end
  end

  test 'returns permission error for new item when user is staff only' do
    staff_user = users(:employee_staff)
    stub_classification(intent: 'new_item', entities: { 'item_name' => 'New Dish', 'item_price' => 10.0 }) do
      result = call_service(query_text: 'add new dish', user: staff_user)
      assert_equal :narrative, result.response_type
      assert_match(/permission/i, result.narrative_text)
    end
  end

  # ---------------------------------------------------------------------------
  # Staff message
  # ---------------------------------------------------------------------------

  test 'returns action card for staff_message intent' do
    stub_classification(intent: 'staff_message', entities: { 'message_topic' => 'new menu launch' }) do
      stub_draft_message_tool(subject: 'Menu Launch', body: 'Exciting news about our new menu!') do
        result = call_service(query_text: 'draft a message about new menu')
        assert_equal :action_card, result.response_type
        assert_equal 'send_staff_message', result.action_card[:tool_name]
        assert result.action_card[:editable]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # AgentWorkflowRun logging
  # ---------------------------------------------------------------------------

  test 'logs an AgentWorkflowRun for each query' do
    stub_classification(intent: 'unknown') do
      assert_difference('AgentWorkflowRun.count', 1) do
        call_service(query_text: 'what time is it?')
      end
    end

    run = AgentWorkflowRun.where(workflow_type: 'staff_copilot', restaurant: @restaurant).last
    assert_not_nil run
    assert_equal 'completed', run.status
    assert_equal 'staff_copilot', run.workflow_type
    assert_equal 'copilot.query', run.trigger_event
  end

  # ---------------------------------------------------------------------------
  # Error handling
  # ---------------------------------------------------------------------------

  test 'returns error response on unexpected exception' do
    OpenaiClient.stub(:new, -> { raise 'LLM exploded' }) do
      result = call_service(query_text: 'anything')
      assert_equal :error, result.response_type
      assert_match(/something went wrong/i, result.narrative_text)
    end
  end

  private

  def call_service(query_text:, user: @owner, **opts)
    Agents::StaffCopilotService.call(
      restaurant: @restaurant,
      user: user,
      query_text: query_text,
      conversation_history: [],
      page_context: '/restaurants/1/menus',
      **opts,
    )
  end

  def stub_classification(intent:, entities: {})
    classification = { intent: intent, entities: entities }
    # Stub the private method on any new instance by patching the class
    Agents::StaffCopilotService.define_method(:classify_intent) { classification }
    yield
  ensure
    Agents::StaffCopilotService.remove_method(:classify_intent)
  end

  def stub_search_tool(items)
    Agents::Tools::SearchMenuItems.stub(:call, ->(_p) { { items: items, total: items.size } }) do
      yield
    end
  end

  def stub_analytics_tool
    data = {
      period: 'last week',
      total_orders: 42,
      total_revenue_cents: 250_000,
      total_revenue_formatted: '€2500.00',
      avg_ticket_cents: 5952,
      avg_ticket_formatted: '€59.52',
      top_items: [{ id: 1, name: 'Burger', quantity_sold: 15, margin_pct: nil }],
      orders: [true],
    }
    Agents::Tools::ReadOrderAnalytics.stub(:call, ->(_p) { data }) do
      yield
    end
  end

  def stub_draft_message_tool(subject:, body:)
    Agents::Tools::DraftStaffMessage.stub(:call, ->(_p) { { subject: subject, body: body } }) do
      yield
    end
  end
end
