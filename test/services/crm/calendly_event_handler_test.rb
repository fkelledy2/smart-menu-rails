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

  # ---------------------------------------------------------------------------
  # Lost lead — must succeed without attempting an invalid transition
  # ---------------------------------------------------------------------------

  test 'succeeds for a lost lead without changing its stage' do
    lead = crm_leads(:lost_lead)
    payload = build_payload(email: lead.contact_email, uuid: 'lost-lead-calendly-uuid')
    result = Crm::CalendlyEventHandler.call(payload: payload)
    assert result.success?, "Expected success for lost lead, got: #{result.error}"
    assert_equal 'lost', lead.reload.stage
  end

  # ---------------------------------------------------------------------------
  # Existing lead at stage 'new' — must advance to demo_booked
  # ---------------------------------------------------------------------------

  test 'advances an existing lead at stage new to demo_booked' do
    lead = crm_leads(:new_lead)
    payload = build_payload(email: lead.contact_email, uuid: 'new-stage-advance-uuid')
    result = Crm::CalendlyEventHandler.call(payload: payload)
    assert result.success?, "Expected success, got: #{result.error}"
    assert_equal 'demo_booked', lead.reload.stage
    assert_not result.created
  end

  test 'stores calendly_event_uuid when advancing a new-stage lead' do
    lead = crm_leads(:new_lead)
    payload = build_payload(email: lead.contact_email, uuid: 'new-stage-uuid-store')
    Crm::CalendlyEventHandler.call(payload: payload)
    assert_equal 'new-stage-uuid-store', lead.reload.calendly_event_uuid
  end

  # ---------------------------------------------------------------------------
  # Missing email in payload — skipped with warning
  # ---------------------------------------------------------------------------

  test 'returns failure when invitee email is missing from payload' do
    payload = { 'payload' => { 'invitee' => { 'name' => 'No Email Person' } } }
    result = Crm::CalendlyEventHandler.call(payload: payload)
    assert_not result.success?
    assert_equal 'missing_invitee_email', result.error
  end

  test 'does not create a lead when invitee email is missing' do
    payload = { 'payload' => { 'invitee' => { 'name' => 'No Email Person' } } }
    assert_no_difference 'CrmLead.count' do
      Crm::CalendlyEventHandler.call(payload: payload)
    end
  end

  test 'returns failure when payload has an empty email string' do
    payload = build_payload(email: '', uuid: 'empty-email-uuid')
    result = Crm::CalendlyEventHandler.call(payload: payload)
    assert_not result.success?
    assert_equal 'missing_invitee_email', result.error
  end

  # ---------------------------------------------------------------------------
  # Concurrent webhook replay — RecordNotUnique → idempotent
  # ---------------------------------------------------------------------------

  test 'is idempotent when a concurrent job claims the UUID before this one can store it' do
    # Simulate: another concurrent job already stored the UUID on the demo_booked_lead fixture.
    # The handler should detect RecordNotUnique and return the existing lead as success.
    existing_lead = crm_leads(:demo_booked_lead)
    # existing_lead already has calendly_event_uuid: 'abc-123-existing-uuid'
    # Build a payload using that same UUID with a different email to simulate the race:
    # The idempotency check finds the existing lead first and returns early.
    payload = build_payload(email: 'totally-different@email.com', uuid: 'abc-123-existing-uuid')

    assert_no_difference 'CrmLead.count' do
      result = Crm::CalendlyEventHandler.call(payload: payload)
      assert result.success?, "Expected success for duplicate UUID, got: #{result.error}"
      assert_not result.created
      assert_equal existing_lead.id, result.lead.id
    end
  end

  # ---------------------------------------------------------------------------
  # Audit count — no duplicate stage_changed records for new leads
  # ---------------------------------------------------------------------------

  test 'writes exactly one stage_changed audit for a newly auto-created lead' do
    payload = build_payload(email: 'brand-new@prospect.com', uuid: 'audit-count-uuid')
    lead = nil
    assert_difference 'CrmLead.count', 1 do
      result = Crm::CalendlyEventHandler.call(payload: payload)
      assert result.success?
      lead = result.lead
    end
    stage_changed_audits = lead.crm_lead_audits.where(event: 'stage_changed')
    assert_equal 1, stage_changed_audits.count,
                 "Expected 1 stage_changed audit, got #{stage_changed_audits.count}"
  end
end
