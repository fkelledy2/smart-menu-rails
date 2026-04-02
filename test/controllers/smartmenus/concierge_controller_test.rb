# frozen_string_literal: true

require 'test_helper'

class Smartmenus::ConciergeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @smartmenu  = smartmenus(:one)
    @restaurant = @smartmenu.menu&.restaurant || restaurants(:one)

    Flipper.enable(:agent_framework)
    Flipper.enable(:agent_customer_concierge, @restaurant)
  end

  def teardown
    Flipper.disable(:agent_framework)
    Flipper.disable(:agent_customer_concierge)
    AgentWorkflowRun.where(workflow_type: 'customer_concierge', restaurant: @restaurant).destroy_all
  end

  # ──────────────────────────────────────────────────────────────
  # Feature flag gates
  # ──────────────────────────────────────────────────────────────

  test 'POST returns 403 when agent_framework flag is disabled' do
    Flipper.disable(:agent_framework)
    post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
         params: { query_text: 'Hello' },
         as: :json
    assert_response :forbidden
  end

  test 'POST returns 403 when agent_customer_concierge flag is disabled for restaurant' do
    Flipper.disable(:agent_customer_concierge)
    post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
         params: { query_text: 'Hello' },
         as: :json
    assert_response :forbidden
  end

  # ──────────────────────────────────────────────────────────────
  # Input validation
  # ──────────────────────────────────────────────────────────────

  test 'POST returns 400 when query_text is blank' do
    post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
         params: { query_text: '' },
         as: :json
    assert_response :bad_request
  end

  test 'POST returns 400 when query_text exceeds 500 characters' do
    long_query = 'a' * 501
    post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
         params: { query_text: long_query },
         as: :json
    assert_response :bad_request
  end

  test 'POST returns 404 for unknown public_token' do
    post smartmenu_concierge_query_path(public_token: 'z' * 64),
         params: { query_text: 'Something tasty' },
         as: :json
    assert_response :not_found
  end

  # ──────────────────────────────────────────────────────────────
  # Happy path
  # ──────────────────────────────────────────────────────────────

  test 'POST returns 200 with items and workflow_run_id on success' do
    stub_service_success do
      post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
           params: { query_text: 'I am vegan, what can I eat?' },
           as: :json
    end

    assert_response :success
    body = response.parsed_body
    assert body.key?('items')
    assert body.key?('workflow_run_id')
    assert_instance_of Array, body['items']
  end

  test 'POST returns 422 when service returns an error' do
    error_result = Agents::CustomerConciergeService::Result.new(
      items: [], basket: nil, workflow_run_id: nil, error: 'Recommendations unavailable right now',
    )

    Agents::CustomerConciergeService.stub(:call, error_result) do
      post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
           params: { query_text: 'What do you have?' },
           as: :json
    end

    assert_response :unprocessable_entity
    body = response.parsed_body
    assert body['error'].present?
  end

  # ──────────────────────────────────────────────────────────────
  # Conversation history
  # ──────────────────────────────────────────────────────────────

  test 'POST passes conversation_history to service' do
    history = [{ role: 'user', content: 'Previous query' }, { role: 'assistant', content: 'Previous answer' }]
    captured_args = {}

    capture_stub = lambda do |**kwargs|
      captured_args.merge!(kwargs)
      Agents::CustomerConciergeService::Result.new(items: [], basket: nil, workflow_run_id: 1, error: nil)
    end

    Agents::CustomerConciergeService.stub(:call, capture_stub) do
      post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
           params: { query_text: 'Follow up', conversation_history: history },
           as: :json
    end

    assert captured_args[:conversation_history].is_a?(Array)
    assert captured_args[:conversation_history].size <= 5
  end

  # ──────────────────────────────────────────────────────────────
  # Malformed conversation_history is safe
  # ──────────────────────────────────────────────────────────────

  test 'POST handles missing conversation_history gracefully' do
    stub_service_success do
      post smartmenu_concierge_query_path(public_token: @smartmenu.public_token),
           params: { query_text: 'Any soup?' },
           as: :json
    end

    assert_response :success
  end

  private

  def stub_service_success(&)
    success_result = Agents::CustomerConciergeService::Result.new(
      items: [{ 'id' => 1, 'name' => 'Salad', 'price' => 10.0, 'explanation' => 'Fresh.' }],
      basket: nil,
      workflow_run_id: 42,
      error: nil,
    )

    Agents::CustomerConciergeService.stub(:call, success_result, &)
  end
end
