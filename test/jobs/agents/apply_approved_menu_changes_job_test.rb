# frozen_string_literal: true

require 'test_helper'

class Agents::ApplyApprovedMenuChangesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @restaurant = restaurants(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'menu_optimization',
      trigger_event: 'menu_optimization.scheduled',
      status: 'completed',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
      completed_at: Time.current,
    )
    @artifact = AgentArtifact.create!(
      agent_workflow_run: @run,
      artifact_type: 'menu_optimization_changeset',
      content: {
        'restaurant_id' => @restaurant.id,
        'analysis_week' => '2026-W14',
        'actions' => [],
        'advisory_pricing' => [],
        'generated_at' => Time.current.iso8601,
      },
      status: 'approved',
      scheduled_apply_at: 1.hour.ago,
    )
  end

  test 'skips artifacts with pending approvals' do
    AgentApproval.create!(
      agent_workflow_run: @run,
      action_type: 'item_rename',
      risk_level: 'low',
      proposed_payload: { target_id: 1, target_name: 'Test', reason: 'test' },
      status: 'pending',
      expires_at: 72.hours.from_now,
    )

    Agents::ApplyApprovedMenuChangesJob.new.perform

    assert_equal 'approved', @artifact.reload.status
  end

  test 'applies artifact when no pending approvals and scheduled_apply_at is past' do
    Agents::ApplyApprovedMenuChangesJob.new.perform
    assert_equal 'applied', @artifact.reload.status
  end

  test 'skips artifact whose scheduled_apply_at is in the future' do
    @artifact.update!(scheduled_apply_at: 1.hour.from_now)
    Agents::ApplyApprovedMenuChangesJob.new.perform
    assert_equal 'approved', @artifact.reload.status
  end

  test 'does not apply artifacts without menu_optimization_changeset type' do
    @artifact.update!(artifact_type: 'growth_digest')
    Agents::ApplyApprovedMenuChangesJob.new.perform
    assert_equal 'approved', @artifact.reload.status
  end

  test 'is queued on agent_default queue' do
    assert_equal :agent_default, Agents::ApplyApprovedMenuChangesJob.queue_name.to_sym
  end
end
