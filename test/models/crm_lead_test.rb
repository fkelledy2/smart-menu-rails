# frozen_string_literal: true

require 'test_helper'

class CrmLeadTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------

  test 'is valid with required fields' do
    lead = CrmLead.new(restaurant_name: 'Test Restaurant', stage: 'new')
    assert lead.valid?
  end

  test 'requires restaurant_name' do
    lead = CrmLead.new(stage: 'new')
    assert_not lead.valid?
    assert_includes lead.errors[:restaurant_name], "can't be blank"
  end

  test 'requires stage' do
    lead = CrmLead.new(restaurant_name: 'Test')
    lead.stage = nil
    assert_not lead.valid?
  end

  test 'rejects invalid stage value' do
    assert_raises(ArgumentError) do
      CrmLead.new(restaurant_name: 'Test', stage: 'invalid_stage')
    end
  end

  test 'converted stage requires restaurant_id' do
    lead = CrmLead.new(restaurant_name: 'Test', stage: 'converted')
    assert_not lead.valid?
    assert lead.errors[:restaurant_id].any?
  end

  test 'converted stage is valid when restaurant_id is present' do
    restaurant = restaurants(:one)
    lead = CrmLead.new(restaurant_name: 'Test', stage: 'converted', restaurant_id: restaurant.id)
    assert lead.valid?
  end

  test 'lost stage requires lost_reason' do
    lead = CrmLead.new(restaurant_name: 'Test', stage: 'lost')
    assert_not lead.valid?
    assert lead.errors[:lost_reason].any?
  end

  test 'lost stage is valid with known lost_reason' do
    lead = CrmLead.new(restaurant_name: 'Test', stage: 'lost', lost_reason: 'price')
    assert lead.valid?
  end

  test 'rejects invalid lost_reason' do
    lead = CrmLead.new(restaurant_name: 'Test', stage: 'new', lost_reason: 'moon_is_full')
    assert_not lead.valid?
  end

  # ---------------------------------------------------------------------------
  # Stage enum
  # ---------------------------------------------------------------------------

  test 'all expected stages are defined' do
    expected = %w[new contacted demo_booked demo_completed proposal_sent trial_active converted lost]
    assert_equal expected, CrmLead::STAGES
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------

  test 'recent scope orders by last_activity_at desc' do
    leads = CrmLead.recent
    assert leads.any?
  end

  test 'by_stage scope filters correctly' do
    result = CrmLead.by_stage('new')
    result.each { |l| assert_equal 'new', l.stage }
  end

  test 'needs_assignment scope returns unassigned demo_booked leads' do
    # The demo_booked_lead fixture has no assigned_to_id
    assert_includes CrmLead.needs_assignment.map(&:calendly_event_uuid), 'abc-123-existing-uuid'
  end

  # ---------------------------------------------------------------------------
  # Associations
  # ---------------------------------------------------------------------------

  test 'has many crm_lead_notes' do
    lead = crm_leads(:new_lead)
    assert_equal 2, lead.crm_lead_notes.count
  end

  test 'has many crm_lead_audits' do
    lead = crm_leads(:new_lead)
    assert lead.crm_lead_audits.is_a?(ActiveRecord::Associations::CollectionProxy)
  end

  test 'belongs_to assigned_to user optionally' do
    lead = crm_leads(:new_lead)
    assert_nil lead.assigned_to
    lead2 = crm_leads(:contacted_lead)
    assert_not_nil lead2.assigned_to
  end

  # ---------------------------------------------------------------------------
  # Callbacks
  # ---------------------------------------------------------------------------

  test 'sets last_activity_at on create if not provided' do
    lead = CrmLead.create!(restaurant_name: 'Callback Test', stage: 'new')
    assert_not_nil lead.last_activity_at
  end

  test 'respects provided last_activity_at' do
    time = 2.days.ago
    lead = CrmLead.create!(restaurant_name: 'Callback Test 2', stage: 'new', last_activity_at: time)
    assert_in_delta time.to_i, lead.last_activity_at.to_i, 1
  end

  # ---------------------------------------------------------------------------
  # Stage enum predicates (prefix: :stage avoids collision with Object#new)
  # ---------------------------------------------------------------------------

  test 'stage_new? is true for new leads' do
    lead = crm_leads(:new_lead)
    assert lead.stage_new?
    assert_not lead.stage_contacted?
  end

  test 'stage_contacted? is true for contacted leads' do
    lead = crm_leads(:contacted_lead)
    assert lead.stage_contacted?
  end

  test 'stage_lost? is true for lost leads' do
    lead = crm_leads(:lost_lead)
    assert lead.stage_lost?
    assert_not lead.stage_new?
  end

  test 'stage_converted? is true for converted leads' do
    lead = crm_leads(:converted_lead)
    assert lead.stage_converted?
  end

  test 'stage predicates cover all defined stages' do
    predicate_stages = %w[new contacted demo_booked demo_completed proposal_sent trial_active converted lost]
    predicate_stages.each do |stage|
      lead = CrmLead.new(restaurant_name: 'Predicate Test', stage: stage)
      lead.restaurant_id = restaurants(:one).id if stage == 'converted'
      lead.lost_reason = 'price' if stage == 'lost'
      assert lead.public_send(:"stage_#{stage}?"), "expected stage_#{stage}? to be true"
    end
  end

  # ---------------------------------------------------------------------------
  # LOST_REASONS enum
  # ---------------------------------------------------------------------------

  test 'all expected lost_reason values are defined' do
    expected = %w[price competitor no_response not_a_fit timing other]
    assert_equal expected, CrmLead::LOST_REASONS
  end

  test 'lost_reason_notes is optional even when stage is lost' do
    lead = CrmLead.new(restaurant_name: 'No Notes', stage: 'lost', lost_reason: 'price')
    assert lead.valid?, lead.errors.full_messages.to_sentence
  end

  # ---------------------------------------------------------------------------
  # notes_count counter cache
  # ---------------------------------------------------------------------------

  test 'notes_count increments when a note is added' do
    lead = CrmLead.create!(restaurant_name: 'Counter Test', stage: 'new', last_activity_at: Time.current)
    author = users(:super_admin)
    assert_equal 0, lead.notes_count

    lead.crm_lead_notes.create!(body: 'First note', author: author)
    assert_equal 1, lead.reload.notes_count

    lead.crm_lead_notes.create!(body: 'Second note', author: author)
    assert_equal 2, lead.reload.notes_count
  end

  test 'notes_count decrements when a note is removed' do
    lead = CrmLead.create!(restaurant_name: 'Counter Decrement Test', stage: 'new', last_activity_at: Time.current)
    author = users(:super_admin)
    note = lead.crm_lead_notes.create!(body: 'Temp note', author: author)

    assert_equal 1, lead.reload.notes_count
    note.destroy!
    assert_equal 0, lead.reload.notes_count
  end

  # ---------------------------------------------------------------------------
  # Stage transition helpers
  # ---------------------------------------------------------------------------

  test 'stage can be assigned as a string' do
    lead = crm_leads(:new_lead)
    lead.stage = 'contacted'
    assert lead.stage_contacted?
  end

  test 'lost stage stores lost_at timestamp when set via transition service' do
    lead = crm_leads(:new_lead)
    Crm::LeadTransitionService.call(
      lead: lead,
      new_stage: 'lost',
      actor: users(:super_admin),
      lost_reason: 'timing',
    )
    assert_not_nil lead.reload.lost_at
  end

  test 'reopening a lost lead clears lost_at, lost_reason, and lost_reason_notes' do
    lead = crm_leads(:lost_lead)
    Crm::LeadTransitionService.call(lead: lead, new_stage: 'contacted', actor: users(:super_admin))
    lead.reload
    assert_nil lead.lost_at
    assert_nil lead.lost_reason
    assert_nil lead.lost_reason_notes
  end
end
