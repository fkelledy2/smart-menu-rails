# frozen_string_literal: true

require 'test_helper'

class Agents::CustomerConciergeServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @smartmenu  = smartmenus(:one)

    # Enable required Flipper flags
    Flipper.enable(:agent_framework)
    Flipper.enable(:agent_customer_concierge, @restaurant)
  end

  def teardown
    Flipper.disable(:agent_framework)
    Flipper.disable(:agent_customer_concierge)
    AgentWorkflowRun.where(workflow_type: 'customer_concierge', restaurant: @restaurant).destroy_all
  end

  test 'returns error result when query is blank' do
    result = call_service(query_text: '')
    assert result.error.present?
    assert_equal [], result.items
  end

  test 'returns error result when query is whitespace only' do
    result = call_service(query_text: '   ')
    assert result.error.present?
  end

  test 'creates an AgentWorkflowRun for the session' do
    stub_concierge_tools(items: sample_items) do
      assert_difference('AgentWorkflowRun.count', 1) do
        call_service(query_text: 'Something vegetarian please')
      end
    end
  end

  test 'AgentWorkflowRun has workflow_type customer_concierge' do
    stub_concierge_tools(items: sample_items) do
      call_service(query_text: 'Any vegan options?')
    end
    run = AgentWorkflowRun.where(workflow_type: 'customer_concierge', restaurant: @restaurant).last
    assert_not_nil run
    assert_equal 'customer_concierge', run.workflow_type
  end

  test 'returns items on success' do
    stub_concierge_tools(items: sample_items) do
      result = call_service(query_text: 'Something vegetarian')
      assert_instance_of Array, result.items
      assert result.error.nil?
    end
  end

  test 'returns error gracefully when OpenAI is unavailable' do
    error_client = Object.new
    def error_client.chat_with_tools(**_kwargs)
      raise OpenaiClient::ApiError, 'Service unavailable'
    end

    OpenaiClient.stub(:new, error_client) do
      result = call_service(query_text: 'I want food')
      assert result.error.present?
      assert_equal [], result.items
    end
  end

  test 'detects basket intent from query' do
    service = Agents::CustomerConciergeService.new(
      restaurant: @restaurant,
      smartmenu:  @smartmenu,
      query_text: 'Build a tapas order for 4 people under €60',
    )

    intent = service.send(:detect_basket_intent, 'Build a tapas order for 4 people under €60')
    assert intent[:detected]
    assert_equal 4, intent[:group_size]
    assert_equal 60.0, intent[:budget]
  end

  test 'does not detect basket intent for simple query' do
    service = Agents::CustomerConciergeService.new(
      restaurant: @restaurant,
      smartmenu:  @smartmenu,
      query_text: 'I am vegan',
    )

    intent = service.send(:detect_basket_intent, 'I am vegan')
    assert_equal false, intent[:detected]
  end

  test 'reuses existing workflow run when workflow_run_id provided' do
    existing_run = AgentWorkflowRun.create!(
      restaurant:       @restaurant,
      workflow_type:    'customer_concierge',
      trigger_event:    'customer_query',
      status:           'completed',
      started_at:       1.minute.ago,
      completed_at:     30.seconds.ago,
      context_snapshot: { 'turn_count' => 1, 'smartmenu_id' => @smartmenu.id },
    )

    stub_concierge_tools(items: sample_items) do
      assert_no_difference('AgentWorkflowRun.count') do
        call_service(query_text: 'follow up question', workflow_run_id: existing_run.id)
      end
    end
  ensure
    existing_run&.destroy
  end

  private

  def call_service(query_text:, workflow_run_id: nil)
    Agents::CustomerConciergeService.call(
      restaurant:      @restaurant,
      smartmenu:       @smartmenu,
      query_text:      query_text,
      workflow_run_id: workflow_run_id,
    )
  end

  def sample_items
    [{ id: 1, name: 'Pizza', price: 12.5, explanation: 'A classic.' }]
  end

  # Stubs out both SearchMenuItems and ComposeRecommendation so tests don't
  # require a live OpenAI key.
  def stub_concierge_tools(items:)
    Agents::Tools::SearchMenuItems.stub(:call, { items: [{ id: 1, name: 'Pizza', price: 12.5 }], total: 1 }) do
      compose_result = { items: items }
      Agents::Tools::ComposeRecommendation.stub(:call, compose_result) do
        yield
      end
    end
  end
end
