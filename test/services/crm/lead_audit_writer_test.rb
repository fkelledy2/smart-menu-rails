# frozen_string_literal: true

require 'test_helper'

class Crm::LeadAuditWriterTest < ActiveSupport::TestCase
  setup do
    @lead  = crm_leads(:new_lead)
    @actor = users(:super_admin)
  end

  test 'creates a CrmLeadAudit record' do
    assert_difference 'CrmLeadAudit.count', 1 do
      Crm::LeadAuditWriter.write(crm_lead: @lead, event: 'stage_changed', actor: @actor)
    end
  end

  test 'sets actor_type to user when actor present' do
    audit = Crm::LeadAuditWriter.write(crm_lead: @lead, event: 'lead_created', actor: @actor)
    assert_equal 'user', audit.actor_type
  end

  test 'sets actor_type to system when actor is nil' do
    audit = Crm::LeadAuditWriter.write(crm_lead: @lead, event: 'stage_changed', actor: nil)
    assert_equal 'system', audit.actor_type
  end

  test 'stores field_name, from_value, to_value' do
    audit = Crm::LeadAuditWriter.write(
      crm_lead: @lead,
      event: 'stage_changed',
      actor: @actor,
      field_name: 'stage',
      from_value: 'new',
      to_value: 'contacted',
    )
    assert_equal 'stage',     audit.field_name
    assert_equal 'new',       audit.from_value
    assert_equal 'contacted', audit.to_value
  end

  test 'stores metadata' do
    audit = Crm::LeadAuditWriter.write(
      crm_lead: @lead,
      event: 'email_sent',
      actor: @actor,
      metadata: { subject: 'Hello', to_email: 'test@example.com' },
    )
    assert_equal 'Hello', audit.metadata['subject']
  end

  test 'sets created_at' do
    audit = Crm::LeadAuditWriter.write(crm_lead: @lead, event: 'note_added', actor: @actor)
    assert_not_nil audit.created_at
  end
end
