# frozen_string_literal: true

require 'test_helper'

class Restaurants::CopilotControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
    @owner      = users(:one)
    @staff_user = users(:employee_staff)
    @other_user = users(:two)  # owner of restaurant :two, no access to restaurant :one

    Flipper.enable(:agent_framework, @restaurant)
    Flipper.enable(:agent_staff_copilot, @restaurant)
    Rails.cache.clear
  end

  def teardown
    Flipper.disable(:agent_framework, @restaurant)
    Flipper.disable(:agent_staff_copilot, @restaurant)
    AgentWorkflowRun.where(workflow_type: 'staff_copilot', restaurant: @restaurant).destroy_all
    Rails.cache.clear
  end

  # ---------------------------------------------------------------------------
  # POST /copilot/query
  # ---------------------------------------------------------------------------

  test 'POST query redirects unauthenticated users' do
    post restaurant_copilot_query_path(@restaurant), params: { query_text: 'hello' }
    assert_redirected_to new_user_session_path
  end

  test 'POST query returns 404 when agent_staff_copilot flag is off' do
    Flipper.disable(:agent_staff_copilot, @restaurant)
    sign_in @owner
    post restaurant_copilot_query_path(@restaurant),
         params: { query_text: 'test' },
         headers: { 'Accept' => 'application/json' }
    assert_response :not_found
  end

  test 'POST query returns 404 when agent_framework flag is off' do
    Flipper.disable(:agent_framework, @restaurant)
    sign_in @owner
    post restaurant_copilot_query_path(@restaurant),
         params: { query_text: 'test' },
         headers: { 'Accept' => 'application/json' }
    assert_response :not_found
  end

  test 'POST query raises Pundit::NotAuthorizedError for unrelated user' do
    sign_in @other_user
    assert_raises(Pundit::NotAuthorizedError) do
      post restaurant_copilot_query_path(@restaurant),
           params: { query_text: 'show revenue' },
           headers: { 'Accept' => 'application/json' }
    end
  end

  test 'POST query returns turbo stream for owner with valid query' do
    sign_in @owner
    stub_copilot_service do
      post restaurant_copilot_query_path(@restaurant),
           params: { query_text: 'show me sales' },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      assert_response :success
    end
  end

  test 'POST query returns JSON for owner with Accept application/json' do
    sign_in @owner
    stub_copilot_service do
      post restaurant_copilot_query_path(@restaurant),
           params: { query_text: 'show me sales' },
           headers: { 'Accept' => 'application/json' }
      assert_response :success
      json = JSON.parse(response.body)
      assert_includes %w[narrative action_card disambiguation error], json['response_type']
    end
  end

  test 'POST query is accessible to staff employee' do
    sign_in @staff_user
    stub_copilot_service do
      post restaurant_copilot_query_path(@restaurant),
           params: { query_text: '86 the burrata' },
           headers: { 'Accept' => 'application/json' }
      assert_response :success
    end
  end

  # ---------------------------------------------------------------------------
  # POST /copilot/confirm
  # ---------------------------------------------------------------------------

  test 'POST confirm redirects unauthenticated users' do
    post restaurant_copilot_confirm_path(@restaurant), params: { tool_name: 'flag_item_unavailable', menuitem_id: 1 }
    assert_redirected_to new_user_session_path
  end

  test 'POST confirm returns 422 for unknown tool_name' do
    sign_in @owner
    post restaurant_copilot_confirm_path(@restaurant),
         params: { tool_name: 'DROP TABLE menuitems' },
         headers: { 'Accept' => 'application/json' }
    assert_response :unprocessable_entity
  end

  test 'POST confirm returns JSON result for valid flag_item_unavailable' do
    sign_in @owner
    menuitem = menuitems(:one)

    post restaurant_copilot_confirm_path(@restaurant),
         params: { tool_name: 'flag_item_unavailable', menuitem_id: menuitem.id, hide: 'true' },
         headers: { 'Accept' => 'application/json' }

    assert_response :success
    json = JSON.parse(response.body)
    assert json['success']
  end

  private

  def stub_copilot_service
    narrative_response = Agents::StaffCopilotService::CopilotResponse.new(
      response_type: :narrative,
      narrative_text: 'Here is what I found.',
      intent_type: 'analytics_query',
      tool_called: 'read_order_analytics',
    )
    Agents::StaffCopilotService.stub(:call, ->(**_kw) { narrative_response }) do
      yield
    end
  end
end
