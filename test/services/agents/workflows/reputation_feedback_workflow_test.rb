# frozen_string_literal: true

require 'test_helper'

module Agents
  module Workflows
    class ReputationFeedbackWorkflowTest < ActiveSupport::TestCase
      def setup
        @restaurant = restaurants(:one)
        Flipper.enable(:agent_reputation_feedback, @restaurant)
        Flipper.enable(:agent_framework, @restaurant)

        @ordr = Ordr.create!(
          restaurant: @restaurant,
          menu: menus(:one),
          tablesetting: tablesettings(:one),
          status: Ordr.statuses[:paid],
        )

        @run = AgentWorkflowRun.create!(
          restaurant: @restaurant,
          workflow_type: 'reputation_feedback',
          trigger_event: 'rating.low',
          status: 'pending',
          context_snapshot: {
            'restaurant_id' => @restaurant.id,
            'ordr_id' => @ordr.id,
            'signal_type' => 'rating.low',
            'stars' => 1,
            'comment' => 'Cold food',
          },
        )
      end

      teardown do
        Flipper.disable(:agent_reputation_feedback, @restaurant)
        Flipper.disable(:agent_framework, @restaurant)
      end

      # --- provision_steps! ---

      test 'provisions 4 workflow steps on first call' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        workflow.send(:provision_steps!)

        assert_equal 4, @run.agent_workflow_steps.count
        assert_equal %w[read_context classify_and_reason write_recovery_draft notify_manager],
                     @run.agent_workflow_steps.ordered.map(&:step_name)
      end

      test 'does not duplicate steps on second provision call' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        workflow.send(:provision_steps!)
        workflow.send(:provision_steps!)

        assert_equal 4, @run.agent_workflow_steps.count
      end

      # --- step_read_context ---

      test 'step_read_context returns signal info from context_snapshot' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        result = workflow.send(:step_read_context)

        assert_equal 'rating.low', result['signal_type']
        assert_equal 1, result['stars']
        assert_equal @ordr.id, result['ordr_id']
        assert_not_nil result['ordr_context']
      end

      test 'step_read_context builds ordr context with items' do
        # Add an ordritem to the order
        Ordritem.create!(
          ordr: @ordr,
          menuitem: menuitems(:one),
          quantity: 2,
          status: Ordritem.statuses[:delivered],
        )

        workflow = ReputationFeedbackWorkflow.new(@run)
        result = workflow.send(:step_read_context)

        assert result['ordr_context']['items'].any?
        assert_equal 1, result['ordr_context']['items'].length
      end

      test 'step_read_context returns empty ordr_context for unknown ordr_id' do
        @run.update!(context_snapshot: @run.context_snapshot.merge('ordr_id' => 999_999))
        workflow = ReputationFeedbackWorkflow.new(@run)
        result = workflow.send(:step_read_context)

        assert_equal({}, result['ordr_context'])
      end

      # --- step_classify_and_reason (payment.abandoned fast path) ---

      test 'classify_and_reason uses fast path for payment.abandoned' do
        @run.update!(
          trigger_event: 'payment.abandoned',
          context_snapshot: @run.context_snapshot.merge('signal_type' => 'payment.abandoned'),
        )
        @run.agent_workflow_steps.create!(
          step_name: 'read_context',
          step_index: 0,
          status: 'completed',
          input_snapshot: {},
          retry_count: 0,
          output_snapshot: {
            'signal_type' => 'payment.abandoned',
            'ordr_id' => @ordr.id,
            'ordr_context' => {},
          },
        )

        workflow = ReputationFeedbackWorkflow.new(@run)
        result = workflow.send(:step_classify_and_reason)

        assert_equal 'high', result['severity']
        assert result['fast_path']
      end

      # --- validated_* helpers ---

      test 'validated_severity returns medium for unknown value' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        assert_equal 'medium', workflow.send(:validated_severity, 'unknown')
      end

      test 'validated_root_cause returns other for unknown value' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        assert_equal 'other', workflow.send(:validated_root_cause, 'lost_booking')
      end

      test 'validated_suggested_action returns direct_message for unknown value' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        assert_equal 'direct_message', workflow.send(:validated_suggested_action, 'random')
      end

      # --- check_systemic_issue ---

      test 'check_systemic_issue returns nil for root_cause other' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        result = workflow.send(:check_systemic_issue, 'other')
        assert_nil result
      end

      test 'check_systemic_issue returns nil below threshold count' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        result = workflow.send(:check_systemic_issue, 'wait_time')
        # Only 1 artifact exists (none) — should be nil
        assert_nil result
      end

      test 'check_systemic_issue returns advisory note when threshold reached' do
        # Create 3 artifacts with wait_time root_cause for this restaurant
        3.times do |i|
          run = AgentWorkflowRun.create!(
            restaurant: @restaurant,
            workflow_type: 'reputation_feedback',
            trigger_event: 'rating.low',
            status: 'completed',
            context_snapshot: {},
            completed_at: Time.current,
          )
          AgentArtifact.create!(
            agent_workflow_run: run,
            artifact_type: 'reputation_recovery',
            status: 'draft',
            content: { 'root_cause' => 'wait_time', 'severity' => 'medium' },
          )
        end

        workflow = ReputationFeedbackWorkflow.new(@run)
        result = workflow.send(:check_systemic_issue, 'wait_time')

        # count (3 existing) + 1 (current) = 4, which is >= SYSTEMIC_ISSUE_MIN_COUNT (3)
        assert_not_nil result
        assert_includes result, 'wait time'
      end

      # --- has_outbound_action? ---

      test 'has_outbound_action? returns true when draft_message present' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        assert workflow.send(:has_outbound_action?, { 'draft_message' => 'Hello' })
      end

      test 'has_outbound_action? returns true when draft_review_response present' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        assert workflow.send(:has_outbound_action?, { 'draft_review_response' => 'Thank you' })
      end

      test 'has_outbound_action? returns false when both absent' do
        workflow = ReputationFeedbackWorkflow.new(@run)
        assert_not workflow.send(:has_outbound_action?, {})
      end

      # --- halting on flag disable ---

      test 'halts and marks run failed when flag disabled mid-run' do
        Flipper.disable(:agent_reputation_feedback, @restaurant)

        workflow = ReputationFeedbackWorkflow.new(@run)
        workflow.call

        @run.reload
        assert @run.failed?
        assert_includes @run.error_message, 'Feature flag disabled'
      end

      # --- Full workflow with stubbed LLM ---

      test 'full workflow creates artifact and approval for low rating' do
        llm_content = '{"severity":"high","root_cause":"quality","suggested_action":"direct_message","draft_message":"Dear customer, we are sorry.","draft_review_response":null}'
        stub_openai_response = {
          'choices' => [{ 'message' => { 'content' => llm_content } }],
        }

        # Add an item to the order
        Ordritem.create!(
          ordr: @ordr,
          menuitem: menuitems(:one),
          quantity: 1,
          status: Ordritem.statuses[:delivered],
        )

        fake_client = Object.new
        fake_client.define_singleton_method(:chat_with_tools) { |**_kwargs| stub_openai_response }

        # Suppress email delivery
        ActionMailer::Base.deliveries.clear

        OpenaiClient.stub(:new, fake_client) do
          AgentReputationMailer.stub(:reputation_alert, ->(*_args, **_kwargs) { double_mailer }) do
            Agents::Workflows::ReputationFeedbackWorkflow.call(@run)
          end
        end

        @run.reload
        assert @run.completed? || @run.awaiting_approval?

        artifact = @run.agent_artifacts.where(artifact_type: 'reputation_recovery').first
        assert_not_nil artifact
        assert_equal 'high', artifact.content['severity']
        assert_equal 'quality', artifact.content['root_cause']
        assert_equal 'Dear customer, we are sorry.', artifact.content['draft_message']

        # Approval should have been created
        approval = @run.agent_approvals.find_by(action_type: 'send_recovery_message')
        assert_not_nil approval
        assert_equal 'high', approval.risk_level
        assert approval.pending?
      end

      private

      def double_mailer
        mailer = Object.new
        def mailer.deliver_later
          # no-op
        end
        mailer
      end
    end
  end
end
