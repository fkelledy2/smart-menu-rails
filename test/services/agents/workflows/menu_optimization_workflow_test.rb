# frozen_string_literal: true

require 'test_helper'

class Agents::Workflows::MenuOptimizationWorkflowTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'menu_optimization',
      trigger_event: 'menu_optimization.requested',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    )
    @workflow = Agents::Workflows::MenuOptimizationWorkflow.new(@run)
  end

  # ---------------------------------------------------------------------------
  # Step provisioning
  # ---------------------------------------------------------------------------

  test 'provision_steps! creates all 5 steps' do
    assert_difference 'AgentWorkflowStep.count', 5 do
      @workflow.send(:provision_steps!)
    end
  end

  test 'provision_steps! does not duplicate on second call' do
    @workflow.send(:provision_steps!)
    assert_no_difference 'AgentWorkflowStep.count' do
      @workflow.send(:provision_steps!)
    end
  end

  test 'step names match STEP_NAMES' do
    @workflow.send(:provision_steps!)
    names = @run.agent_workflow_steps.order(:step_index).pluck(:step_name)
    assert_equal Agents::Workflows::MenuOptimizationWorkflow::STEP_NAMES, names
  end

  # ---------------------------------------------------------------------------
  # Step 1: read_performance
  # ---------------------------------------------------------------------------

  test 'step_read_performance returns expected keys' do
    result = @workflow.send(:step_read_performance)
    assert result.key?(:restaurant_id)
    assert result.key?(:restaurant_name)
    assert result.key?(:tagged_items)
    assert result.key?(:total_items)
    assert result.key?(:window_days)
    assert result.key?(:analysis_week)
  end

  test 'step_read_performance returns correct restaurant_id' do
    result = @workflow.send(:step_read_performance)
    assert_equal @restaurant.id, result[:restaurant_id]
  end

  test 'step_read_performance returns array for tagged_items' do
    result = @workflow.send(:step_read_performance)
    assert_instance_of Array, result[:tagged_items]
  end

  test 'tagged items have expected structure when items exist' do
    result = @workflow.send(:step_read_performance)
    items = result[:tagged_items]
    if items.any?
      item = items.first
      assert item.key?('menuitem_id')
      assert item.key?('name')
      assert item.key?('tags')
      assert item.key?('order_count')
      assert item.key?('margin_pct')
      assert item.key?('has_image')
      assert item.key?('hidden')
    end
  end

  test 'analysis_week has expected format' do
    result = @workflow.send(:step_read_performance)
    assert_match(/\A\d{4}-W\d{2}\z/, result[:analysis_week])
  end

  # ---------------------------------------------------------------------------
  # compute_tags
  # ---------------------------------------------------------------------------

  test 'compute_tags returns fast_mover for high order count' do
    tags = @workflow.send(:compute_tags, order_cnt: 10, median_orders: 5, margin_pct: 50.0, order_share: 0.1)
    assert_includes tags, 'fast_mover'
    assert_not_includes tags, 'slow_mover'
  end

  test 'compute_tags returns slow_mover for zero orders' do
    tags = @workflow.send(:compute_tags, order_cnt: 0, median_orders: 5, margin_pct: 50.0, order_share: 0.0)
    assert_includes tags, 'slow_mover'
  end

  test 'compute_tags returns high_margin for margin >= 60' do
    tags = @workflow.send(:compute_tags, order_cnt: 5, median_orders: 5, margin_pct: 65.0, order_share: 0.1)
    assert_includes tags, 'high_margin'
    assert_not_includes tags, 'low_margin'
  end

  test 'compute_tags returns low_margin for margin < 30' do
    tags = @workflow.send(:compute_tags, order_cnt: 5, median_orders: 5, margin_pct: 20.0, order_share: 0.1)
    assert_includes tags, 'low_margin'
    assert_not_includes tags, 'high_margin'
  end

  test 'compute_tags returns high_conversion for high order_share' do
    tags = @workflow.send(:compute_tags, order_cnt: 10, median_orders: 5, margin_pct: 50.0, order_share: 0.20)
    assert_includes tags, 'high_conversion'
  end

  test 'compute_tags returns low_conversion for zero orders and low share' do
    tags = @workflow.send(:compute_tags, order_cnt: 0, median_orders: 5, margin_pct: 0.0, order_share: 0.0)
    assert_includes tags, 'low_conversion'
  end

  # ---------------------------------------------------------------------------
  # compute_median
  # ---------------------------------------------------------------------------

  test 'compute_median returns 0 for empty array' do
    assert_equal 0, @workflow.send(:compute_median, [])
  end

  test 'compute_median returns correct value for odd array' do
    assert_equal 3, @workflow.send(:compute_median, [1, 2, 3, 4, 5])
  end

  test 'compute_median returns correct value for even array' do
    assert_equal 2.5, @workflow.send(:compute_median, [1, 2, 3, 4])
  end

  # ---------------------------------------------------------------------------
  # idempotency key
  # ---------------------------------------------------------------------------

  test 'build_idempotency_key returns consistent SHA256 for same inputs' do
    key1 = @workflow.send(:build_idempotency_key, '2026-W14', 'item_rename', 42)
    key2 = @workflow.send(:build_idempotency_key, '2026-W14', 'item_rename', 42)
    assert_equal key1, key2
  end

  test 'build_idempotency_key differs for different action types' do
    key1 = @workflow.send(:build_idempotency_key, '2026-W14', 'item_rename', 42)
    key2 = @workflow.send(:build_idempotency_key, '2026-W14', 'item_suppress', 42)
    assert_not_equal key1, key2
  end

  test 'build_idempotency_key is a valid SHA256 hex string' do
    key = @workflow.send(:build_idempotency_key, '2026-W14', 'item_feature', 99)
    assert_match(/\A[a-f0-9]{64}\z/, key)
  end

  # ---------------------------------------------------------------------------
  # classify_action
  # ---------------------------------------------------------------------------

  test 'classify_action returns auto_approve for image_queue' do
    assert_equal 'auto_approve', @workflow.send(:classify_action, 'image_queue')
  end

  test 'classify_action returns advisory for price_suggestion' do
    assert_equal 'advisory', @workflow.send(:classify_action, 'price_suggestion')
  end

  test 'classify_action returns require_approval for item_rename' do
    assert_equal 'require_approval', @workflow.send(:classify_action, 'item_rename')
  end

  test 'classify_action returns require_approval for section_reorder' do
    assert_equal 'require_approval', @workflow.send(:classify_action, 'section_reorder')
  end

  test 'classify_action returns require_approval for item_suppress' do
    assert_equal 'require_approval', @workflow.send(:classify_action, 'item_suppress')
  end

  test 'classify_action returns require_approval for item_feature' do
    assert_equal 'require_approval', @workflow.send(:classify_action, 'item_feature')
  end

  # ---------------------------------------------------------------------------
  # validate_and_sanitise_change_set
  # ---------------------------------------------------------------------------

  test 'validate_and_sanitise_change_set removes unknown target_ids' do
    # inject a perf output stub
    step = @run.agent_workflow_steps.create!(
      step_name: 'read_performance',
      step_index: 0,
      status: 'completed',
      input_snapshot: {},
      output_snapshot: {
        'tagged_items' => [{ 'menuitem_id' => 1, 'name' => 'Pizza' }],
        'analysis_week' => '2026-W14',
      },
      retry_count: 0,
    )

    parsed = {
      'actions' => [
        { 'action_type' => 'item_rename', 'target_id' => 1, 'target_name' => 'Pizza', 'reason' => 'test' },
        { 'action_type' => 'item_suppress', 'target_id' => 999, 'target_name' => 'Unknown', 'reason' => 'test' },
      ],
    }

    tagged_items = [{ 'menuitem_id' => 1 }]
    result = @workflow.send(:validate_and_sanitise_change_set, parsed, tagged_items)
    assert_equal 1, result['actions'].size
    assert_equal 'item_rename', result['actions'].first['action_type']
  end

  test 'validate_and_sanitise_change_set removes unknown action types' do
    step = @run.agent_workflow_steps.create!(
      step_name: 'read_performance',
      step_index: 0,
      status: 'completed',
      input_snapshot: {},
      output_snapshot: { 'tagged_items' => [{ 'menuitem_id' => 1 }], 'analysis_week' => '2026-W14' },
      retry_count: 0,
    )

    parsed = {
      'actions' => [
        { 'action_type' => 'INVALID_ACTION', 'target_id' => 1, 'target_name' => 'X', 'reason' => 'test' },
      ],
    }

    result = @workflow.send(:validate_and_sanitise_change_set, parsed, [{ 'menuitem_id' => 1 }])
    assert_equal 0, result['actions'].size
  end

  # ---------------------------------------------------------------------------
  # step_policy_validate
  # ---------------------------------------------------------------------------

  test 'step_policy_validate classifies price_suggestion as advisory' do
    @run.agent_workflow_steps.create!(
      step_name: 'optimisation_reason', step_index: 1, status: 'completed',
      input_snapshot: {}, retry_count: 0,
      output_snapshot: {
        'actions' => [
          {
            'action_type' => 'price_suggestion',
            'target_id' => 1,
            'target_name' => 'Burger',
            'reason' => 'Underpriced',
            'suggested_price' => 12.50,
          },
        ],
        'analysis_week' => '2026-W14',
      },
    )

    result = @workflow.send(:step_policy_validate)
    advisory = result[:advisory_actions]
    assert_equal 1, advisory.size
    assert_equal 'advisory', advisory.first['disposition']
  end

  test 'step_policy_validate classifies image_queue as auto_approve' do
    @run.agent_workflow_steps.create!(
      step_name: 'optimisation_reason', step_index: 1, status: 'completed',
      input_snapshot: {}, retry_count: 0,
      output_snapshot: {
        'actions' => [
          {
            'action_type' => 'image_queue',
            'target_id' => 1,
            'target_name' => 'Pasta',
            'reason' => 'No image',
          },
        ],
        'analysis_week' => '2026-W14',
      },
    )

    result = @workflow.send(:step_policy_validate)
    approvable = result[:approvable_actions]
    assert_equal 1, approvable.size
    assert_equal 'auto_approve', approvable.first['disposition']
  end

  # ---------------------------------------------------------------------------
  # write_change_set — price_suggestion must never create AgentApproval
  # ---------------------------------------------------------------------------

  test 'price_suggestion action never creates an AgentApproval record' do
    # Provision steps with a price_suggestion only
    @run.agent_workflow_steps.create!(
      step_name: 'read_performance', step_index: 0, status: 'completed',
      input_snapshot: {}, retry_count: 0,
      output_snapshot: { 'tagged_items' => [], 'analysis_week' => '2026-W14' },
    )
    @run.agent_workflow_steps.create!(
      step_name: 'optimisation_reason', step_index: 1, status: 'completed',
      input_snapshot: {}, retry_count: 0,
      output_snapshot: {
        'actions' => [
          {
            'action_type' => 'price_suggestion',
            'disposition' => 'advisory',
            'target_id' => 1,
            'target_name' => 'Steak',
            'reason' => 'Margin low',
            'suggested_price' => 25.0,
            'advisory_note' => 'Consider pricing at €25',
          },
        ],
        'analysis_week' => '2026-W14',
      },
    )
    @run.agent_workflow_steps.create!(
      step_name: 'policy_validate', step_index: 2, status: 'completed',
      input_snapshot: {}, retry_count: 0,
      output_snapshot: {
        'actions' => [
          {
            'action_type' => 'price_suggestion',
            'disposition' => 'advisory',
            'target_id' => 1,
            'target_name' => 'Steak',
            'reason' => 'Margin low',
          },
        ],
        'advisory_actions' => [
          { 'action_type' => 'price_suggestion', 'disposition' => 'advisory', 'target_id' => 1 },
        ],
        'approvable_actions' => [],
        'analysis_week' => '2026-W14',
      },
    )

    @run.agent_workflow_steps.create!(
      step_name: 'write_change_set', step_index: 3, status: 'pending',
      input_snapshot: {}, retry_count: 0, output_snapshot: {},
    )

    assert_no_difference 'AgentApproval.count' do
      @workflow.send(:step_write_change_set)
    end
  end

  # ---------------------------------------------------------------------------
  # Idempotency: duplicate run same week does not create duplicate approvals
  # ---------------------------------------------------------------------------

  test 'duplicate idempotency key prevents duplicate AgentApproval creation' do
    existing_key = @workflow.send(:build_idempotency_key, '2026-W14', 'item_rename', 42)
    AgentApproval.create!(
      agent_workflow_run: @run,
      action_type: 'item_rename',
      risk_level: 'low',
      proposed_payload: { 'target_id' => 42, 'target_name' => 'X', 'reason' => 'test' },
      status: 'pending',
      expires_at: 72.hours.from_now,
      idempotency_key: existing_key,
    )

    # Attempting to create another with same key should fail at DB level
    assert_raises(ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid) do
      AgentApproval.create!(
        agent_workflow_run: @run,
        action_type: 'item_rename',
        risk_level: 'low',
        proposed_payload: { 'target_id' => 42, 'target_name' => 'X', 'reason' => 'dup' },
        status: 'pending',
        expires_at: 72.hours.from_now,
        idempotency_key: existing_key,
      )
    end
  end

  # ---------------------------------------------------------------------------
  # parse_json_from_llm
  # ---------------------------------------------------------------------------

  test 'parse_json_from_llm handles plain JSON' do
    result = @workflow.send(:parse_json_from_llm, '{"actions": []}')
    assert_equal [], result['actions']
  end

  test 'parse_json_from_llm strips markdown fences' do
    content = "```json\n{\"actions\": []}\n```"
    result  = @workflow.send(:parse_json_from_llm, content)
    assert_equal [], result['actions']
  end

  test 'parse_json_from_llm raises JSON::ParserError for invalid content' do
    assert_raises(JSON::ParserError) do
      @workflow.send(:parse_json_from_llm, 'not json at all with no braces')
    end
  end

  # ---------------------------------------------------------------------------
  # Flipper flag mid-run guard
  # ---------------------------------------------------------------------------

  test 'call halts run gracefully when flag is disabled mid-run' do
    Flipper.disable(:agent_menu_optimization, @restaurant)

    @workflow.call

    @run.reload
    assert_equal 'failed', @run.status
  ensure
    Flipper.disable(:agent_menu_optimization, @restaurant)
  end
end
