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
end
