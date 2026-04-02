# frozen_string_literal: true

require 'test_helper'

class Agents::Workflows::ManagerDigestWorkflowTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'growth_digest',
      trigger_event: 'manager_digest.scheduled',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    )
    @workflow = Agents::Workflows::ManagerDigestWorkflow.new(@run)
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
    assert_equal Agents::Workflows::ManagerDigestWorkflow::STEP_NAMES, names
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
      assert item.key?('buckets')
      assert item.key?('order_count')
      assert item.key?('margin_pct')
    end
  end

  # ---------------------------------------------------------------------------
  # compute_buckets
  # ---------------------------------------------------------------------------

  test 'compute_buckets returns top_mover for high order count' do
    buckets = @workflow.send(:compute_buckets,
                             order_cnt: 20, median_orders: 10, margin_pct: 50.0, order_share: 0.1,)
    assert_includes buckets, 'top_mover'
    assert_not_includes buckets, 'slow_mover'
  end

  test 'compute_buckets returns slow_mover for zero orders' do
    buckets = @workflow.send(:compute_buckets,
                             order_cnt: 0, median_orders: 5, margin_pct: 50.0, order_share: 0.0,)
    assert_includes buckets, 'slow_mover'
  end

  test 'compute_buckets returns high_margin for margin >= 60' do
    buckets = @workflow.send(:compute_buckets,
                             order_cnt: 5, median_orders: 5, margin_pct: 65.0, order_share: 0.1,)
    assert_includes buckets, 'high_margin'
  end

  test 'compute_buckets returns low_margin for margin < 30' do
    buckets = @workflow.send(:compute_buckets,
                             order_cnt: 5, median_orders: 5, margin_pct: 20.0, order_share: 0.1,)
    assert_includes buckets, 'low_margin'
  end

  test 'compute_buckets returns low_friction for high order_share' do
    buckets = @workflow.send(:compute_buckets,
                             order_cnt: 10, median_orders: 5, margin_pct: 40.0, order_share: 0.20,)
    assert_includes buckets, 'low_friction'
  end

  test 'compute_buckets can return multiple buckets' do
    buckets = @workflow.send(:compute_buckets,
                             order_cnt: 20, median_orders: 10, margin_pct: 65.0, order_share: 0.25,)
    assert_includes buckets, 'top_mover'
    assert_includes buckets, 'high_margin'
    assert_includes buckets, 'low_friction'
  end

  # ---------------------------------------------------------------------------
  # compute_median
  # ---------------------------------------------------------------------------

  test 'compute_median returns 0 for empty array' do
    assert_equal 0, @workflow.send(:compute_median, [])
  end

  test 'compute_median returns middle value for odd array' do
    assert_equal 3, @workflow.send(:compute_median, [1, 2, 3, 4, 5])
  end

  test 'compute_median returns average of two middle values for even array' do
    assert_equal 2.5, @workflow.send(:compute_median, [1, 2, 3, 4])
  end

  # ---------------------------------------------------------------------------
  # Step 2: growth_reason (LLM call — stubbed)
  # ---------------------------------------------------------------------------

  test 'step_growth_reason returns fallback when no tagged_items' do
    # Inject empty read_performance step output
    @workflow.send(:provision_steps!)
    step = @run.agent_workflow_steps.find_by(step_name: 'read_performance')
    step.mark_running!
    step.mark_completed!({
      'restaurant_id' => @restaurant.id,
      'tagged_items' => [],
    })

    result = @workflow.send(:step_growth_reason)
    assert result.key?(:top_performers)
    assert result.key?(:underperformers)
    assert result.key?(:weekend_recommendation)
  end

  test 'fallback_growth_reason uses top_mover and slow_mover buckets' do
    perf = {
      'tagged_items' => [
        { 'menuitem_id' => 1, 'name' => 'Burger', 'buckets' => ['top_mover'] },
        { 'menuitem_id' => 2, 'name' => 'Salad',  'buckets' => ['slow_mover'] },
      ],
    }
    result = @workflow.send(:fallback_growth_reason, perf)
    assert_equal 1, result[:top_performers].size
    assert_equal 1, result[:underperformers].size
    assert result[:fallback]
  end

  # ---------------------------------------------------------------------------
  # Step 3: copy_draft (depends on DraftMarketingCopy tool — stubbed)
  # ---------------------------------------------------------------------------

  test 'step_copy_draft returns empty copy when no tagged_items' do
    @workflow.send(:provision_steps!)
    step = @run.agent_workflow_steps.find_by(step_name: 'read_performance')
    step.mark_running!
    step.mark_completed!({ 'tagged_items' => [], 'restaurant_id' => @restaurant.id })

    Agents::Tools::DraftMarketingCopy.stub(:call, { instagram_caption: '', email_body: '' }) do
      result = @workflow.send(:step_copy_draft)
      assert_nil result[:featured_item]
    end
  end

  test 'step_copy_draft picks high_margin item when available' do
    @workflow.send(:provision_steps!)
    step = @run.agent_workflow_steps.find_by(step_name: 'read_performance')
    step.mark_running!
    step.mark_completed!({
      'tagged_items' => [
        { 'menuitem_id' => 1, 'name' => 'Pasta', 'buckets' => ['top_mover'], 'description' => 'Great pasta' },
        { 'menuitem_id' => 2, 'name' => 'Steak', 'buckets' => ['high_margin'], 'description' => 'Premium steak' },
      ],
      'establishment_type' => 'casual dining',
    })

    stub_copy = { instagram_caption: 'Try our steak!', email_body: 'Feature the steak this weekend.' }
    Agents::Tools::DraftMarketingCopy.stub(:call, stub_copy) do
      result = @workflow.send(:step_copy_draft)
      # featured_item is a symbol-key hash built by the workflow
      assert_equal 2, result[:featured_item][:menuitem_id]
      assert_equal 'Try our steak!', result[:instagram_caption]
    end
  end

  # ---------------------------------------------------------------------------
  # Step 4: compose_digest
  # ---------------------------------------------------------------------------

  test 'step_compose_digest returns required keys' do
    @workflow.send(:provision_steps!)
    inject_completed_step('read_performance', {
      'restaurant_id' => @restaurant.id, 'tagged_items' => [], 'window_days' => 7, 'total_items' => 0,
    })
    inject_completed_step('growth_reason', {
      'top_performers' => [], 'underperformers' => [],
      'repricing_candidates' => [], 'friction_items' => [],
      'weekend_recommendation' => 'Push the daily special.',
    })
    inject_completed_step('copy_draft', {
      'instagram_caption' => 'Check us out!', 'email_body' => 'Join us this weekend.',
      'featured_item' => { 'menuitem_id' => 1, 'name' => 'Burger' },
    })

    stub_summary = { summary: 'Great week overall.' }
    Agents::Tools::ComposeManagerSummary.stub(:call, stub_summary) do
      result = @workflow.send(:step_compose_digest)
      assert result.key?(:narrative)
      assert result.key?(:insights)
      assert result.key?(:marketing_copy)
      assert result.key?(:weekend_recommendation)
      assert result.key?(:generated_at)
    end
  end

  # ---------------------------------------------------------------------------
  # Step 5: notify_manager
  # ---------------------------------------------------------------------------

  test 'step_notify_manager creates an approved artifact' do
    @workflow.send(:provision_steps!)
    inject_completed_step('read_performance', { 'restaurant_id' => @restaurant.id, 'tagged_items' => [] })
    inject_completed_step('growth_reason', {
      'top_performers' => [], 'underperformers' => [],
      'repricing_candidates' => [], 'friction_items' => [],
      'weekend_recommendation' => 'Promote the weekend special.',
    })
    inject_completed_step('copy_draft', { 'instagram_caption' => '', 'email_body' => '', 'featured_item' => nil })
    inject_completed_step('compose_digest', {
      'narrative' => 'Good week.', 'insights' => [], 'marketing_copy' => {},
      'weekend_recommendation' => 'Promote!', 'generated_at' => Time.current.iso8601,
    })

    assert_difference 'AgentArtifact.count', 1 do
      # Stub mailer to avoid email delivery in tests — any call count
      null_message = Object.new
      null_message.define_singleton_method(:deliver_later) { nil }
      AgentDigestMailer.stub(:weekly_digest, null_message) do
        @workflow.send(:step_notify_manager)
      end
    end

    artifact = AgentArtifact.where(agent_workflow_run: @run, artifact_type: 'growth_digest').last
    assert_not_nil artifact
    assert_equal 'approved', artifact.status
  end

  # ---------------------------------------------------------------------------
  # managers_and_owners
  # ---------------------------------------------------------------------------

  test 'managers_and_owners returns users for active managers' do
    users = @workflow.send(:managers_and_owners)
    assert_instance_of Array, users
    # Fixture employee 'one' is role 1 (manager) for restaurant one
    assert users.map(&:id).include?(users(:one).id) if users.any?
  end

  # ---------------------------------------------------------------------------
  # Full pipeline (integration with LLM stubs)
  # ---------------------------------------------------------------------------

  test 'call transitions run to completed when all steps succeed' do
    perf_result = {
      restaurant_id: @restaurant.id,
      restaurant_name: @restaurant.name,
      establishment_type: 'casual dining',
      window_days: 7,
      tagged_items: [],
      total_items: 0,
    }
    reason_result = {
      top_performers: [], underperformers: [], repricing_candidates: [], friction_items: [],
      weekend_recommendation: 'Push the daily special.',
    }
    copy_result = { instagram_caption: 'Try us!', email_body: 'Join us.', featured_item: nil }
    digest_result = {
      narrative: 'Good week.',
      insights: [],
      marketing_copy: {},
      weekend_recommendation: 'Push the daily special.',
      generated_at: Time.current.iso8601,
    }

    null_message = Object.new
    null_message.define_singleton_method(:deliver_later) { nil }

    @workflow.stub(:step_read_performance, perf_result) do
      @workflow.stub(:step_growth_reason, reason_result) do
        @workflow.stub(:step_copy_draft, copy_result) do
          @workflow.stub(:step_compose_digest, digest_result) do
            AgentDigestMailer.stub(:weekly_digest, null_message) do
              Agents::Workflows::ManagerDigestWorkflow.call(@run)
            end
          end
        end
      end
    end

    @run.reload
    assert @run.completed?, "Expected completed, got: #{@run.status} — #{@run.error_message}"
    assert AgentArtifact.exists?(agent_workflow_run: @run, artifact_type: 'growth_digest')
  end

  test 'call marks run as failed on unhandled exception' do
    # Stub step_read_performance to raise so the run transitions to failed
    @workflow.stub(:step_read_performance, -> { raise StandardError, 'DB error' }) do
      @workflow.call
    end
    @run.reload
    assert @run.failed?, "Expected failed, got: #{@run.status}"
    assert_includes @run.error_message, 'DB error'
  end

  # ---------------------------------------------------------------------------
  # parse_json_from_llm
  # ---------------------------------------------------------------------------

  test 'parse_json_from_llm strips markdown fences' do
    raw = "```json\n{\"key\": \"value\"}\n```"
    result = @workflow.send(:parse_json_from_llm, raw)
    assert_equal 'value', result['key']
  end

  test 'parse_json_from_llm extracts embedded JSON from prose' do
    raw = 'Here is the data: {"key": "value"} — end.'
    result = @workflow.send(:parse_json_from_llm, raw)
    assert_equal 'value', result['key']
  end

  test 'parse_json_from_llm raises on invalid JSON' do
    assert_raises JSON::ParserError do
      @workflow.send(:parse_json_from_llm, 'no json here at all')
    end
  end

  private

  def inject_completed_step(step_name, output)
    step = @run.agent_workflow_steps.find_by(step_name: step_name)
    return unless step

    step.mark_running!
    step.mark_completed!(output)
  end
end
