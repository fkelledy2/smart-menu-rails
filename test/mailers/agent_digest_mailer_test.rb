# frozen_string_literal: true

require 'test_helper'

class AgentDigestMailerTest < ActionMailer::TestCase
  def setup
    @restaurant = restaurants(:one)
    @user       = users(:one)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'growth_digest',
      trigger_event: 'manager_digest.scheduled',
      status: 'completed',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    )
    @artifact = AgentArtifact.create!(
      agent_workflow_run: @run,
      artifact_type: 'growth_digest',
      status: 'approved',
      content: {
        narrative: 'Good week overall.',
        insights: [
          { 'type' => 'top_performer', 'menuitem_id' => 1, 'name' => 'Burger', 'reason' => 'High orders' },
        ],
        marketing_copy: {
          'instagram_caption' => 'Try our Burger! #food #yum',
          'email_body' => 'Feature: the Burger.',
          'featured_item' => { 'menuitem_id' => 1, 'name' => 'Burger' },
        },
        weekend_recommendation: 'Push the daily special this Saturday.',
        generated_at: Time.current.iso8601,
      },
    )
  end

  # ---------------------------------------------------------------------------
  # weekly_digest
  # ---------------------------------------------------------------------------

  test 'weekly_digest sends to recipient email' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_equal [@user.email], mail.to
  end

  test 'weekly_digest subject contains restaurant name' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_includes mail.subject, @restaurant.name
  end

  test 'weekly_digest subject contains "weekly growth digest"' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_match(/weekly growth digest/i, mail.subject)
  end

  test 'weekly_digest html body contains narrative' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_includes mail.html_part.body.to_s, 'Good week overall.'
  end

  test 'weekly_digest html body contains weekend recommendation' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_includes mail.html_part.body.to_s, 'Push the daily special this Saturday.'
  end

  test 'weekly_digest html body contains instagram caption' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_includes mail.html_part.body.to_s, 'Try our Burger!'
  end

  test 'weekly_digest text part is present' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_not_nil mail.text_part
    assert mail.text_part.body.to_s.length.positive?
  end

  test 'weekly_digest text body contains restaurant name' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_includes mail.text_part.body.to_s, @restaurant.name
  end

  # ---------------------------------------------------------------------------
  # on_demand_digest
  # ---------------------------------------------------------------------------

  test 'on_demand_digest sends to recipient email' do
    mail = AgentDigestMailer.on_demand_digest(@restaurant, @artifact, @user)
    assert_equal [@user.email], mail.to
  end

  test 'on_demand_digest subject contains restaurant name' do
    mail = AgentDigestMailer.on_demand_digest(@restaurant, @artifact, @user)
    assert_includes mail.subject, @restaurant.name
  end

  test 'on_demand_digest subject mentions digest ready' do
    mail = AgentDigestMailer.on_demand_digest(@restaurant, @artifact, @user)
    assert_match(/digest.*ready/i, mail.subject)
  end

  test 'on_demand_digest sends from hello@mellow.menu' do
    mail = AgentDigestMailer.weekly_digest(@restaurant, @artifact, @user)
    assert_match(/hello@mellow\.menu/, mail.from.first)
  end
end
