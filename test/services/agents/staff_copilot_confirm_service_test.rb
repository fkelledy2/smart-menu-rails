# frozen_string_literal: true

require 'test_helper'

class Agents::StaffCopilotConfirmServiceTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @owner      = users(:one)
    @manager    = users(:two)
    @staff_user = users(:employee_staff)

    Flipper.enable(:agent_framework)
    Flipper.enable(:agent_staff_copilot, @restaurant)
  end

  def teardown
    Flipper.disable(:agent_framework)
    Flipper.disable(:agent_staff_copilot)
  end

  # ---------------------------------------------------------------------------
  # Tool allowlist
  # ---------------------------------------------------------------------------

  test 'rejects unknown tool_name' do
    result = call_confirm(tool_name: 'drop_database', confirm_params: {})
    assert_not result.success?
    assert_match(/unknown action/i, result.message)
  end

  test 'rejects raw SQL injection attempt via tool_name' do
    result = call_confirm(tool_name: "flag_item_unavailable; DROP TABLE menuitems; --", confirm_params: {})
    assert_not result.success?
  end

  # ---------------------------------------------------------------------------
  # flag_item_unavailable
  # ---------------------------------------------------------------------------

  test 'hides a menuitem when user is owner' do
    menuitem = menuitems(:one)
    assert_not menuitem.hidden

    result = call_confirm(
      tool_name:      'flag_item_unavailable',
      confirm_params: { menuitem_id: menuitem.id, hide: true },
    )

    assert result.success?, "Expected success but got: #{result.message}"
    assert menuitem.reload.hidden
  end

  test 'shows a hidden menuitem when user is owner' do
    menuitem = menuitems(:one)
    menuitem.update!(hidden: true)

    result = call_confirm(
      tool_name:      'flag_item_unavailable',
      confirm_params: { menuitem_id: menuitem.id, hide: false },
    )

    assert result.success?
    assert_not menuitem.reload.hidden
  end

  test 'staff user can toggle availability' do
    menuitem = menuitems(:one)

    result = call_confirm(
      tool_name:      'flag_item_unavailable',
      confirm_params: { menuitem_id: menuitem.id, hide: true },
      user:           @staff_user,
    )

    assert result.success?
  end

  test 'returns failure when menuitem not found' do
    result = call_confirm(
      tool_name:      'flag_item_unavailable',
      confirm_params: { menuitem_id: 999_999, hide: true },
    )

    assert_not result.success?
    assert_match(/not found/i, result.message)
  end

  test 'returns failure when menuitem belongs to different restaurant' do
    other_restaurant = restaurants(:two)
    menuitem = menuitems(:one)
    # menuitems(:one) belongs to restaurant :one, not :two

    result = Agents::StaffCopilotConfirmService.call(
      restaurant:     other_restaurant,
      user:           other_restaurant.user,
      tool_name:      'flag_item_unavailable',
      confirm_params: { menuitem_id: menuitem.id, hide: true },
    )

    assert_not result.success?
    assert_match(/not found/i, result.message)
  end

  # ---------------------------------------------------------------------------
  # create_menu_item
  # ---------------------------------------------------------------------------

  test 'creates a menu item when user is owner' do
    assert_difference('Menuitem.count', 1) do
      result = call_confirm(
        tool_name:      'create_menu_item',
        confirm_params: {
          name:          'Test Special',
          price_cents:   2500,
          description:   'A test dish',
          menusection_id: menusections(:one).id,
          allergen_names: [],
        },
      )
      assert result.success?, "Expected success but got: #{result.message}"
    end
  end

  test 'refuses to create item for staff-only user' do
    assert_no_difference('Menuitem.count') do
      result = call_confirm(
        tool_name:      'create_menu_item',
        confirm_params: { name: 'Test', price_cents: 1000 },
        user:           @staff_user,
      )
      assert_not result.success?
      assert_match(/permission/i, result.message)
    end
  end

  test 'returns failure when name is blank' do
    result = call_confirm(
      tool_name:      'create_menu_item',
      confirm_params: { name: '', price_cents: 1000, menusection_id: menusections(:one).id },
    )
    assert_not result.success?
    assert_match(/name is required/i, result.message)
  end

  # ---------------------------------------------------------------------------
  # update_menu_item
  # ---------------------------------------------------------------------------

  test 'updates description when user is manager' do
    menuitem = menuitems(:one)
    new_desc = 'Brand new description for testing'

    result = call_confirm(
      tool_name:      'update_menu_item',
      confirm_params: { menuitem_id: menuitem.id, description: new_desc },
    )

    assert result.success?, result.message
    assert_equal new_desc, menuitem.reload.description
  end

  test 'refuses menu edit for staff-only user' do
    menuitem = menuitems(:one)

    result = call_confirm(
      tool_name:      'update_menu_item',
      confirm_params: { menuitem_id: menuitem.id, price_cents: 9999 },
      user:           @staff_user,
    )

    assert_not result.success?
    assert_match(/permission/i, result.message)
  end

  test 'returns failure when no changes specified' do
    result = call_confirm(
      tool_name:      'update_menu_item',
      confirm_params: { menuitem_id: menuitems(:one).id },
    )
    assert_not result.success?
    assert_match(/no changes/i, result.message)
  end

  # ---------------------------------------------------------------------------
  # send_staff_message
  # ---------------------------------------------------------------------------

  test 'enqueues mailer jobs when user is owner' do
    result = call_confirm(
      tool_name:      'send_staff_message',
      confirm_params: { subject: 'Test Subject', body: 'Test body message.' },
    )
    assert result.success?, result.message
    assert_match(/message sent/i, result.message)
  end

  test 'refuses to send message for staff-only user' do
    result = call_confirm(
      tool_name:      'send_staff_message',
      confirm_params: { subject: 'Test', body: 'Body' },
      user:           @staff_user,
    )
    assert_not result.success?
    assert_match(/permission/i, result.message)
  end

  test 'returns failure when subject or body is blank' do
    result = call_confirm(
      tool_name:      'send_staff_message',
      confirm_params: { subject: '', body: 'Some body' },
    )
    assert_not result.success?
    assert_match(/required/i, result.message)
  end

  private

  def call_confirm(tool_name:, confirm_params:, user: @owner)
    Agents::StaffCopilotConfirmService.call(
      restaurant:     @restaurant,
      user:           user,
      tool_name:      tool_name,
      confirm_params: confirm_params,
    )
  end
end
