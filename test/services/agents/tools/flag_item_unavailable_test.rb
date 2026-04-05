# frozen_string_literal: true

require 'test_helper'

class Agents::Tools::FlagItemUnavailableTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @menuitem = menuitems(:one)
    @menuitem.update!(hidden: false)

    @run = AgentWorkflowRun.create!(
      restaurant: @restaurant,
      workflow_type: 'service_operations',
      trigger_event: 'inventory.low',
      status: 'pending',
      context_snapshot: { 'restaurant_id' => @restaurant.id },
    )

    @approved_approval = AgentApproval.create!(
      agent_workflow_run: @run,
      action_type: 'item_86',
      risk_level: 'medium',
      status: 'approved',
      expires_at: 1.hour.from_now,
      reviewer: users(:one),
      reviewed_at: Time.current,
      proposed_payload: {
        'menuitem_id'   => @menuitem.id,
        'menuitem_name' => @menuitem.name,
        'current_stock' => 1,
        'action'        => 'set_hidden_true',
      },
    )
  end

  def teardown
    @menuitem.update!(hidden: false)
  end

  test 'tool_name is flag_item_unavailable' do
    assert_equal 'flag_item_unavailable', Agents::Tools::FlagItemUnavailable.tool_name
  end

  test 'description is present' do
    assert Agents::Tools::FlagItemUnavailable.description.present?
  end

  test 'input_schema requires menuitem_id and approval_id' do
    schema = Agents::Tools::FlagItemUnavailable.input_schema
    assert_includes schema[:required], 'menuitem_id'
    assert_includes schema[:required], 'approval_id'
  end

  test 'hides the menuitem when called with a valid approved approval' do
    result = Agents::Tools::FlagItemUnavailable.call(
      'menuitem_id' => @menuitem.id,
      'approval_id' => @approved_approval.id,
    )

    assert result[:success], "Expected success but got: #{result.inspect}"
    @menuitem.reload
    assert @menuitem.hidden?, 'Menuitem should be hidden after confirmation'
  end

  test 'raises UnauthorisedActionError when approval is not found' do
    assert_raises Agents::UnauthorisedActionError do
      Agents::Tools::FlagItemUnavailable.call(
        'menuitem_id' => @menuitem.id,
        'approval_id' => 999_999,
      )
    end

    @menuitem.reload
    assert_not @menuitem.hidden?, 'Menuitem should NOT be hidden when approval is missing'
  end

  test 'raises UnauthorisedActionError when approval is pending (not approved)' do
    pending_approval = AgentApproval.create!(
      agent_workflow_run: @run,
      action_type: 'item_86',
      risk_level: 'medium',
      status: 'pending',
      expires_at: 1.hour.from_now,
      proposed_payload: { 'menuitem_id' => @menuitem.id, 'action' => 'set_hidden_true' },
    )

    assert_raises Agents::UnauthorisedActionError do
      Agents::Tools::FlagItemUnavailable.call(
        'menuitem_id' => @menuitem.id,
        'approval_id' => pending_approval.id,
      )
    end
  end

  test 'raises UnauthorisedActionError when approval is for a different menuitem' do
    other_item = menuitems(:two)
    wrong_approval = AgentApproval.create!(
      agent_workflow_run: @run,
      action_type: 'item_86',
      risk_level: 'medium',
      status: 'approved',
      expires_at: 1.hour.from_now,
      reviewer: users(:one),
      reviewed_at: Time.current,
      proposed_payload: {
        'menuitem_id' => other_item.id,
        'action'      => 'set_hidden_true',
      },
    )

    assert_raises Agents::UnauthorisedActionError do
      Agents::Tools::FlagItemUnavailable.call(
        'menuitem_id' => @menuitem.id,
        'approval_id' => wrong_approval.id,
      )
    end
  end

  test 'raises UnauthorisedActionError when approval_id is nil' do
    assert_raises Agents::UnauthorisedActionError do
      Agents::Tools::FlagItemUnavailable.call(
        'menuitem_id' => @menuitem.id,
        'approval_id' => nil,
      )
    end
  end

  test 'raises UnauthorisedActionError when menuitem_id does not match approval payload' do
    # The approval is for @menuitem.id, calling with a different menuitem_id fails the cross-check
    assert_raises(Agents::UnauthorisedActionError) do
      Agents::Tools::FlagItemUnavailable.call(
        'menuitem_id' => 999_999,
        'approval_id' => @approved_approval.id,
      )
    end
  end

  test 'returns error hash when menuitem does not exist but ids match' do
    # Create an approval for a non-existent menuitem_id
    nonexistent_approval = AgentApproval.create!(
      agent_workflow_run: @run,
      action_type: 'item_86',
      risk_level: 'medium',
      status: 'approved',
      expires_at: 1.hour.from_now,
      reviewer: users(:one),
      reviewed_at: Time.current,
      proposed_payload: {
        'menuitem_id' => 999_999,
        'action'      => 'set_hidden_true',
      },
    )

    result = Agents::Tools::FlagItemUnavailable.call(
      'menuitem_id' => 999_999,
      'approval_id' => nonexistent_approval.id,
    )

    assert_not result[:success]
    assert_match(/not found/, result[:error])
  end

  test 'raises UnauthorisedActionError when called without any params' do
    assert_raises Agents::UnauthorisedActionError do
      Agents::Tools::FlagItemUnavailable.call({})
    end
  end
end
