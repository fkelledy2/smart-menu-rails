# frozen_string_literal: true

require 'test_helper'

class Agents::MenuImportPublisherTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @ocr_import = ocr_menu_imports(:completed_import)
    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'menu_import',
      trigger_event: 'menu.import.requested',
      status: 'pending',
      context_snapshot: {
        'restaurant_id' => @restaurant.id,
        'ocr_menu_import_id' => @ocr_import.id,
      },
    )
    @user = users(:one)
  end

  test 'returns failure when pending approvals exist' do
    AgentApproval.create!(
      agent_workflow_run: @run,
      action_type: 'menu_item_publish',
      risk_level: 'medium',
      proposed_payload: {},
      status: 'pending',
      expires_at: 72.hours.from_now,
    )

    result = Agents::MenuImportPublisher.call(
      workflow_run: @run,
      ocr_import: @ocr_import,
      restaurant: @restaurant,
      published_by: @user,
    )

    assert_not result.success?
    assert_match(/pending approvals/, result.error)
  end

  test 'returns failure when no confirmed sections' do
    # completed_import has sections but we'll use a non-completed import
    import = ocr_menu_imports(:pending_import)

    result = Agents::MenuImportPublisher.call(
      workflow_run: @run,
      ocr_import: import,
      restaurant: @restaurant,
      published_by: @user,
    )

    assert_not result.success?
  end

  test 'confirm_approved_items! marks auto_approved items as confirmed' do
    item = ocr_menu_items(:bruschetta)
    item.update_column(:agent_approval_status, 'auto_approved')

    publisher = Agents::MenuImportPublisher.new(
      workflow_run: @run,
      ocr_import: @ocr_import,
      restaurant: @restaurant,
      published_by: @user,
    )
    publisher.send(:confirm_approved_items!)

    assert item.reload.is_confirmed
  end

  test 'confirm_approved_items! does not confirm rejected items' do
    item = ocr_menu_items(:bruschetta)
    item.update_column(:agent_approval_status, 'rejected')
    item.update_column(:is_confirmed, true)

    publisher = Agents::MenuImportPublisher.new(
      workflow_run: @run,
      ocr_import: @ocr_import,
      restaurant: @restaurant,
      published_by: @user,
    )
    publisher.send(:confirm_approved_items!)

    assert_not item.reload.is_confirmed
  end

  test 'confirm_approved_items! auto-confirms items without agent status if high confidence and no allergens' do
    item = ocr_menu_items(:bruschetta)
    item.update_columns(agent_approval_status: nil, allergens: [], confidence_score: 0.95)

    publisher = Agents::MenuImportPublisher.new(
      workflow_run: @run,
      ocr_import: @ocr_import,
      restaurant: @restaurant,
      published_by: @user,
    )
    publisher.send(:confirm_approved_items!)

    assert item.reload.is_confirmed
  end
end
