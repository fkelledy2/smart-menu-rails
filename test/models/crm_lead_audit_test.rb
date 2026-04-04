# frozen_string_literal: true

require 'test_helper'

class CrmLeadAuditTest < ActiveSupport::TestCase
  test 'is valid with required fields' do
    lead = crm_leads(:new_lead)
    audit = CrmLeadAudit.new(
      crm_lead: lead,
      actor_type: 'user',
      event: 'lead_created',
      created_at: Time.current,
    )
    assert audit.valid?
  end

  test 'requires event' do
    lead = crm_leads(:new_lead)
    audit = CrmLeadAudit.new(crm_lead: lead, actor_type: 'user', created_at: Time.current)
    assert_not audit.valid?
    assert audit.errors[:event].any?
  end

  test 'rejects invalid actor_type' do
    lead = crm_leads(:new_lead)
    audit = CrmLeadAudit.new(
      crm_lead: lead,
      actor_type: 'robot',
      event: 'lead_created',
      created_at: Time.current,
    )
    assert_not audit.valid?
  end

  test 'raises ImmutableRecordError on update attempt' do
    audit = crm_lead_audits(:lead_created_audit)
    # Use a valid event value so the inclusion validation passes and the
    # before_update immutability callback is reached.
    assert_raises(CrmLeadAudit::ImmutableRecordError) do
      audit.update!(event: 'stage_changed')
    end
  end

  test 'raises ImmutableRecordError on destroy attempt' do
    audit = crm_lead_audits(:lead_created_audit)
    assert_raises(CrmLeadAudit::ImmutableRecordError) do
      audit.destroy!
    end
  end

  # ---------------------------------------------------------------------------
  # Event inclusion validation (Fix 2b)
  # ---------------------------------------------------------------------------

  test 'rejects event not in EVENTS list' do
    lead = crm_leads(:new_lead)
    audit = CrmLeadAudit.new(
      crm_lead: lead,
      actor_type: 'system',
      event: 'not_a_real_event',
      created_at: Time.current,
    )
    assert_not audit.valid?
    assert_includes audit.errors[:event], 'is not included in the list'
  end

  test 'all EVENTS values pass validation' do
    lead = crm_leads(:new_lead)
    CrmLeadAudit::EVENTS.each do |event|
      audit = CrmLeadAudit.new(
        crm_lead: lead,
        actor_type: 'system',
        event: event,
        created_at: Time.current,
      )
      assert audit.valid?, "Expected #{event} to be valid, got: #{audit.errors.full_messages}"
    end
  end

  test 'actor is optional (system events)' do
    lead = crm_leads(:new_lead)
    audit = CrmLeadAudit.create!(
      crm_lead: lead,
      actor: nil,
      actor_type: 'system',
      event: 'stage_changed',
      created_at: Time.current,
    )
    assert_nil audit.actor
  end
end
