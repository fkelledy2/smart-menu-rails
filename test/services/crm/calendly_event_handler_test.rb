# frozen_string_literal: true

require 'test_helper'

class Crm::CalendlyEventHandlerTest < ActiveSupport::TestCase
  KNOWN_EMAIL = 'pierre@lamaison.fr' # maps to crm_leads(:contacted_lead)
  UNKNOWN_EMAIL = 'new.prospect@somewhere.com'

  def build_payload(email:, name: 'Test Person', uuid: 'fresh-uuid-001')
    {
      'payload' => {
        'event' => { 'uuid' => uuid },
        'invitee' => { 'email' => email, 'name' => name },
      },
    }
  end

  # ---------------------------------------------------------------------------
  # Known lead — advance to demo_booked
  # ---------------------------------------------------------------------------

  test 'advances known lead to demo_booked' do
    lead = crm_leads(:contacted_lead)
    payload = build_payload(email: KNOWN_EMAIL, uuid: 'advance-to-demo-uuid')
    result = Crm::CalendlyEventHandler.call(payload: payload)
    assert result.success?
    assert_equal 'demo_booked', lead.reload.stage
  end

  test 'stores calendly_event_uuid on known lead' do
    lead = crm_leads(:contacted_lead)
    payload = build_payload(email: KNOWN_EMAIL, uuid: 'store-uuid-test')
    Crm::CalendlyEventHandler.call(payload: payload)
    assert_equal 'store-uuid-test', lead.reload.calendly_event_uuid
  end

  # ---------------------------------------------------------------------------
  # Unknown email — auto-creates lead
  # ---------------------------------------------------------------------------

  test 'auto-creates a new lead when no matching email exists' do
    payload = build_payload(email: UNKNOWN_EMAIL, uuid: 'new-lead-uuid')
    assert_difference 'CrmLead.count', 1 do
      result = Crm::CalendlyEventHandler.call(payload: payload)
      assert result.success?
      assert result.created
    end
  end

  test 'auto-created lead has correct attributes' do
    payload = build_payload(email: UNKNOWN_EMAIL, uuid: 'auto-lead-uuid-2', name: 'Auto Person')
    Crm::CalendlyEventHandler.call(payload: payload)
    lead = CrmLead.find_by(calendly_event_uuid: 'auto-lead-uuid-2')
    assert_not_nil lead
    assert_equal 'calendly', lead.source
    assert_nil lead.assigned_to_id
    assert_equal 'demo_booked', lead.stage
    assert_equal UNKNOWN_EMAIL, lead.contact_email
  end

  # ---------------------------------------------------------------------------
  # Idempotency — duplicate event UUID
  # ---------------------------------------------------------------------------

  test 'is idempotent when same event UUID arrives twice' do
    payload = build_payload(email: UNKNOWN_EMAIL, uuid: 'idempotent-uuid-xyz')
    Crm::CalendlyEventHandler.call(payload: payload)

    assert_no_difference 'CrmLead.count' do
      result = Crm::CalendlyEventHandler.call(payload: payload)
      assert result.success?
      assert_not result.created
    end
  end

  # ---------------------------------------------------------------------------
  # Lead already past demo_booked — no transition
  # ---------------------------------------------------------------------------

  test 'does not regress a converted lead to demo_booked' do
    lead = crm_leads(:converted_lead)
    payload = build_payload(email: lead.contact_email, uuid: 'no-regress-uuid')
    result = Crm::CalendlyEventHandler.call(payload: payload)
    assert result.success?
    assert_equal 'converted', lead.reload.stage
  end

  test 'does not regress a demo_booked lead (already at that stage)' do
    lead = crm_leads(:demo_booked_lead)
    payload = build_payload(email: lead.contact_email, uuid: 'already-booked-uuid')
    result = Crm::CalendlyEventHandler.call(payload: payload)
    assert result.success?
    assert_equal 'demo_booked', lead.reload.stage
  end
end
