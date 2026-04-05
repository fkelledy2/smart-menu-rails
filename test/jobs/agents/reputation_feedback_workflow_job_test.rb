# frozen_string_literal: true

require 'test_helper'

module Agents
  class ReputationFeedbackWorkflowJobTest < ActiveJob::TestCase
    def setup
      @restaurant = restaurants(:one)
      @run = AgentWorkflowRun.create!(
        restaurant: @restaurant,
        workflow_type: 'reputation_feedback',
        trigger_event: 'rating.low',
        status: 'pending',
        context_snapshot: { 'restaurant_id' => @restaurant.id },
      )
      Flipper.enable(:agent_reputation_feedback, @restaurant)
      Flipper.enable(:agent_framework, @restaurant)
    end

    teardown do
      Flipper.disable(:agent_reputation_feedback, @restaurant)
      Flipper.disable(:agent_framework, @restaurant)
    end

    test 'enqueues on agent_high queue' do
      assert_equal :agent_high, Agents::ReputationFeedbackWorkflowJob.queue_name.to_sym
    end

    test 'skips run if not found' do
      assert_nothing_raised do
        Agents::ReputationFeedbackWorkflowJob.new.perform(999_999)
      end
    end

    test 'skips run if already completed' do
      @run.update!(status: 'completed', completed_at: Time.current)

      workflow_called = false
      Agents::Workflows::ReputationFeedbackWorkflow.stub(:call, ->(run) { workflow_called = true }) do
        Agents::ReputationFeedbackWorkflowJob.new.perform(@run.id)
      end

      assert_not workflow_called, 'Workflow should not be called for a completed run'
    end

    test 'skips run if flag disabled' do
      Flipper.disable(:agent_reputation_feedback, @restaurant)

      workflow_called = false
      Agents::Workflows::ReputationFeedbackWorkflow.stub(:call, ->(run) { workflow_called = true }) do
        Agents::ReputationFeedbackWorkflowJob.new.perform(@run.id)
      end

      assert_not workflow_called, 'Workflow should not be called when flag is disabled'
    end

    test 'calls workflow when run is pending and flag enabled' do
      called = false
      Agents::Workflows::ReputationFeedbackWorkflow.stub(:call, ->(run) { called = true }) do
        Agents::ReputationFeedbackWorkflowJob.new.perform(@run.id)
      end
      assert called
    end
  end
end
