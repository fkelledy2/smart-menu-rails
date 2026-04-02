# frozen_string_literal: true

require 'test_helper'

class Restaurants::AgentWorkbenchDigestsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
    @owner      = users(:one)
    @other_user = users(:two)
  end

  # ---------------------------------------------------------------------------
  # GET /restaurants/:restaurant_id/agent_workbench/digests
  # ---------------------------------------------------------------------------

  test 'GET digests redirects unauthenticated users' do
    get digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'GET digests succeeds for restaurant owner' do
    sign_in @owner
    get digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_response :success
  end

  test 'GET digests forbidden for unrelated user' do
    sign_in @other_user
    get digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_response :redirect # Pundit redirects after not-authorised
  end

  test 'GET digests shows Generate Now button when flag enabled' do
    sign_in @owner
    Flipper.enable(:agent_growth_digest, @restaurant)
    get digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_response :success
    assert_select 'button', text: /Generate Now/i
  ensure
    Flipper.disable(:agent_growth_digest, @restaurant)
  end

  test 'GET digests shows flag notice when agent_growth_digest disabled' do
    sign_in @owner
    Flipper.disable(:agent_growth_digest, @restaurant)
    get digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_response :success
    assert_select '.alert', text: /agent_growth_digest/
  end

  # ---------------------------------------------------------------------------
  # POST /restaurants/:restaurant_id/agent_workbench/generate_digest
  # ---------------------------------------------------------------------------

  test 'POST generate_digest redirects unauthenticated users' do
    post generate_digest_restaurant_agent_workbench_index_path(@restaurant)
    assert_redirected_to new_user_session_path
  end

  test 'POST generate_digest with flag disabled redirects with alert' do
    sign_in @owner
    Flipper.disable(:agent_growth_digest, @restaurant)
    post generate_digest_restaurant_agent_workbench_index_path(@restaurant)
    assert_redirected_to digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_match(/not.*enabled/i, flash[:alert])
  end

  test 'POST generate_digest with flag enabled creates run and redirects' do
    sign_in @owner
    Flipper.enable(:agent_growth_digest, @restaurant)
    Flipper.enable(:agent_framework, @restaurant)

    # Cancel the existing active growth_digest run from fixtures so we get a clean state
    AgentWorkflowRun
      .for_restaurant(@restaurant.id)
      .where(workflow_type: 'growth_digest')
      .active
      .update_all(status: 'cancelled')

    assert_difference 'AgentWorkflowRun.count', 1 do
      post generate_digest_restaurant_agent_workbench_index_path(@restaurant)
    end

    assert_redirected_to digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_match(/started/i, flash[:notice])
  ensure
    Flipper.disable(:agent_growth_digest, @restaurant)
    Flipper.disable(:agent_framework, @restaurant)
  end

  test 'POST generate_digest with active run redirects with notice (no duplicate)' do
    sign_in @owner
    Flipper.enable(:agent_growth_digest, @restaurant)
    Flipper.enable(:agent_framework, @restaurant)

    # Create an existing active run
    AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'growth_digest',
      trigger_event: 'manager_digest.requested',
      status: 'running',
      context_snapshot: {},
    )

    assert_no_difference 'AgentWorkflowRun.count' do
      post generate_digest_restaurant_agent_workbench_index_path(@restaurant)
    end

    assert_redirected_to digests_restaurant_agent_workbench_index_path(@restaurant)
    assert_match(/already being generated/i, flash[:notice])
  ensure
    Flipper.disable(:agent_growth_digest, @restaurant)
    Flipper.disable(:agent_framework, @restaurant)
  end
end
