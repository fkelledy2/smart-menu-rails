# frozen_string_literal: true

require 'test_helper'

# Tests for agent-specific extensions on OcrMenuImport.
class OcrMenuImportAgentTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'emits an agent domain event after_create via publish!' do
    assert_difference 'AgentDomainEvent.count', 1 do
      OcrMenuImport.create!(
        restaurant: @restaurant,
        name: 'Test Import',
        status: 'pending',
      )
    end
  end

  test 'emitted event has correct event_type' do
    import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Event Test Import',
      status: 'pending',
    )
    event = AgentDomainEvent.find_by(
      event_type: 'menu.import.requested',
      idempotency_key: "menu.import.requested:ocr_menu_import:#{import.id}",
    )
    assert event, 'Expected domain event not found'
    assert_equal import.restaurant_id, event.payload['restaurant_id']
    assert_equal import.id, event.payload['ocr_menu_import_id']
  end

  test 'emitted event is idempotent — does not create a duplicate' do
    import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Idempotency Test Import',
      status: 'pending',
    )
    key = "menu.import.requested:ocr_menu_import:#{import.id}"
    count_before = AgentDomainEvent.where(idempotency_key: key).count
    assert_equal 1, count_before

    # Calling publish! again with the same key should not create a new record
    AgentDomainEvent.publish!(
      event_type: 'menu.import.requested',
      payload: { restaurant_id: @restaurant.id, ocr_menu_import_id: import.id },
      idempotency_key: key,
    )
    assert_equal 1, AgentDomainEvent.where(idempotency_key: key).count
  end

  test 'belongs_to agent_workflow_run optional association' do
    import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'No Run Import',
      status: 'pending',
    )
    assert_nil import.agent_workflow_run
  end

  test 'agent_status validates inclusion' do
    import = OcrMenuImport.new(
      restaurant: @restaurant,
      name: 'Validation Test',
      status: 'pending',
      agent_status: 'invalid_status',
    )
    assert_not import.valid?
    assert import.errors[:agent_status].any?
  end

  test 'agent_status allows nil' do
    import = OcrMenuImport.new(
      restaurant: @restaurant,
      name: 'Nil Status Test',
      status: 'pending',
      agent_status: nil,
    )
    assert import.valid?
  end

  test 'agent_status allows all valid statuses' do
    OcrMenuImport::AGENT_STATUSES.each do |status|
      import = OcrMenuImport.new(
        restaurant: @restaurant,
        name: "Status #{status}",
        status: 'pending',
        agent_status: status,
      )
      assert import.valid?, "Expected #{status} to be valid but got: #{import.errors.full_messages}"
    end
  end
end
