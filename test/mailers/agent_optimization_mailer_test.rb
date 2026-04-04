# frozen_string_literal: true

require 'test_helper'

class AgentOptimizationMailerTest < ActionMailer::TestCase
  def setup
    @restaurant = restaurants(:one)
    @user       = users(:one)
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
      status: 'draft',
      content: {
        'restaurant_id' => @restaurant.id,
        'analysis_week' => '2026-W14',
        'actions' => [
          {
            'action_type' => 'item_rename',
            'disposition' => 'require_approval',
            'target_id' => 1,
            'target_name' => 'Classic Burger',
            'reason' => 'Name could be more appetising',
            'new_name' => 'Signature Beef Burger',
          },
          {
            'action_type' => 'item_feature',
            'disposition' => 'require_approval',
            'target_id' => 2,
            'target_name' => 'Truffle Fries',
            'reason' => 'High margin, low visibility',
          },
        ],
        'advisory_pricing' => [],
        'generated_at' => Time.current.iso8601,
      },
    )
  end

  test 'optimization_ready sends to recipient email' do
    mail = AgentOptimizationMailer.optimization_ready(@restaurant, @artifact, @user, 2)
    assert_equal [@user.email], mail.to
  end

  test 'optimization_ready subject contains restaurant name' do
    mail = AgentOptimizationMailer.optimization_ready(@restaurant, @artifact, @user, 2)
    assert_includes mail.subject, @restaurant.name
  end

  test 'optimization_ready subject mentions optimisation' do
    mail = AgentOptimizationMailer.optimization_ready(@restaurant, @artifact, @user, 2)
    assert_match(/optimis/i, mail.subject)
  end

  test 'optimization_ready html body references pending actions' do
    mail = AgentOptimizationMailer.optimization_ready(@restaurant, @artifact, @user, 2)
    body = mail.html_part.body.to_s
    assert_includes body, 'Classic Burger'
  end

  test 'optimization_ready text part is present' do
    mail = AgentOptimizationMailer.optimization_ready(@restaurant, @artifact, @user, 2)
    assert_not_nil mail.text_part
    assert mail.text_part.body.to_s.length.positive?
  end

  test 'optimization_ready text body contains restaurant name' do
    mail = AgentOptimizationMailer.optimization_ready(@restaurant, @artifact, @user, 2)
    assert_includes mail.text_part.body.to_s, @restaurant.name
  end

  test 'optimization_ready sends from admin@mellow.menu' do
    mail = AgentOptimizationMailer.optimization_ready(@restaurant, @artifact, @user, 2)
    assert_match(/admin@mellow\.menu/, mail.from.first)
  end
end
