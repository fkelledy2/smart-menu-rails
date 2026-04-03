# frozen_string_literal: true

require 'test_helper'

class Crm::LeadTransitionServiceTest < ActiveSupport::TestCase
  setup do
    @actor = users(:super_admin)
  end

  # ---------------------------------------------------------------------------
  # Valid forward transitions
  # ---------------------------------------------------------------------------

  test 'transitions new to contacted' do
    lead = crm_leads(:new_lead)
    result = Crm::LeadTransitionService.call(lead: lead, new_stage: 'contacted', actor: @actor)
    assert result.success?
    assert_equal 'contacted', lead.reload.stage
  end

  test 'transitions contacted to demo_booked' do
    lead = crm_leads(:contacted_lead)
    result = Crm::LeadTransitionService.call(lead: lead, new_stage: 'demo_booked', actor: @actor)
    assert result.success?
    assert_equal 'demo_booked', lead.reload.stage
  end

  test 'writes an audit record on successful transition' do
    lead = crm_leads(:new_lead)
    assert_difference 'CrmLeadAudit.count', 1 do
      Crm::LeadTransitionService.call(lead: lead, new_stage: 'contacted', actor: @actor)
    end
    audit = lead.crm_lead_audits.order(created_at: :desc).first
    assert_equal 'stage_changed', audit.event
    assert_equal 'new', audit.from_value
    assert_equal 'contacted', audit.to_value
  end

  test 'updates last_activity_at on transition' do
    lead = crm_leads(:new_lead)
    old_time = lead.last_activity_at
    travel 1.minute do
      Crm::LeadTransitionService.call(lead: lead, new_stage: 'contacted', actor: @actor)
    end
    assert lead.reload.last_activity_at > old_time
  end

  # ---------------------------------------------------------------------------
  # Invalid backward transitions
  # ---------------------------------------------------------------------------

  test 'cannot transition contacted back to new' do
    lead = crm_leads(:contacted_lead)
    result = Crm::LeadTransitionService.call(lead: lead, new_stage: 'new', actor: @actor)
    assert_not result.success?
    assert_includes result.error, 'Cannot transition'
  end

  test 'converted lead cannot transition further' do
    lead = crm_leads(:converted_lead)
    result = Crm::LeadTransitionService.call(lead: lead, new_stage: 'trial_active', actor: @actor)
    assert_not result.success?
  end

  # ---------------------------------------------------------------------------
  # Precondition: convert requires restaurant_id
  # ---------------------------------------------------------------------------

  test 'contacted can transition to proposal_sent' do
    lead = crm_leads(:contacted_lead)
    result = Crm::LeadTransitionService.call(
      lead: lead,
      new_stage: 'proposal_sent',
      actor: @actor,
    )
    # proposal_sent is a valid forward transition from contacted
    assert result.success?
    assert_equal 'proposal_sent', lead.reload.stage
  end

  test 'cannot convert from trial_active without restaurant_id' do
    lead = crm_leads(:demo_booked_lead)
    lead.update!(assigned_to: @actor)
    # Advance to trial_active via multiple transitions
    Crm::LeadTransitionService.call(lead: lead, new_stage: 'demo_completed', actor: @actor)
    Crm::LeadTransitionService.call(lead: lead, new_stage: 'proposal_sent', actor: @actor)
    Crm::LeadTransitionService.call(lead: lead, new_stage: 'trial_active', actor: @actor)
    lead.reload

    result = Crm::LeadTransitionService.call(
      lead: lead,
      new_stage: 'converted',
      actor: @actor,
      restaurant_id: nil,
    )
    assert_not result.success?
    assert_includes result.error, 'restaurant'
  end

  # ---------------------------------------------------------------------------
  # Precondition: lost requires lost_reason
  # ---------------------------------------------------------------------------

  test 'cannot mark as lost without lost_reason' do
    lead = crm_leads(:new_lead)
    result = Crm::LeadTransitionService.call(
      lead: lead,
      new_stage: 'lost',
      actor: @actor,
    )
    assert_not result.success?
    assert_includes result.error, 'lost reason'
  end

  test 'marks as lost with valid lost_reason' do
    lead = crm_leads(:new_lead)
    result = Crm::LeadTransitionService.call(
      lead: lead,
      new_stage: 'lost',
      actor: @actor,
      lost_reason: 'price',
      lost_reason_notes: 'Too expensive',
    )
    assert result.success?
    assert_equal 'lost', lead.reload.stage
    assert_equal 'price', lead.lost_reason
    assert_not_nil lead.lost_at
  end

  # ---------------------------------------------------------------------------
  # Re-opening a lost lead
  # ---------------------------------------------------------------------------

  test 'can reopen lost lead to contacted' do
    lead = crm_leads(:lost_lead)
    result = Crm::LeadTransitionService.call(lead: lead, new_stage: 'contacted', actor: @actor)
    assert result.success?
    assert_equal 'contacted', lead.reload.stage
    assert_nil lead.lost_reason
    assert_nil lead.lost_at
  end

  # ---------------------------------------------------------------------------
  # Idempotency (already in target stage)
  # ---------------------------------------------------------------------------

  test 'returns success if already in target stage (idempotent)' do
    lead = crm_leads(:new_lead)
    result = Crm::LeadTransitionService.call(lead: lead, new_stage: 'new', actor: @actor)
    assert result.success?
  end

  # ---------------------------------------------------------------------------
  # System actor (no actor)
  # ---------------------------------------------------------------------------

  test 'succeeds with nil actor (system-triggered)' do
    lead = crm_leads(:new_lead)
    result = Crm::LeadTransitionService.call(lead: lead, new_stage: 'contacted', actor: nil)
    assert result.success?
    audit = lead.crm_lead_audits.order(created_at: :desc).first
    assert_equal 'system', audit.actor_type
    assert_nil audit.actor
  end
end
