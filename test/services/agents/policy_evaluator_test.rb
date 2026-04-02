# frozen_string_literal: true

require 'test_helper'

class Agents::PolicyEvaluatorTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
  end

  test 'returns :auto_approve when restaurant policy is auto_approve=true' do
    # auto_approve_read fixture has auto_approve: true for read_restaurant_context
    result = Agents::PolicyEvaluator.call(
      action_type: 'read_restaurant_context',
      restaurant_id: @restaurant.id,
    )
    assert_equal :auto_approve, result
  end

  test 'returns :require_approval when restaurant policy is auto_approve=false' do
    # require_approval_patch fixture has auto_approve: false for propose_menu_patch
    result = Agents::PolicyEvaluator.call(
      action_type: 'propose_menu_patch',
      restaurant_id: @restaurant.id,
    )
    assert_equal :require_approval, result
  end

  test 'returns :require_approval when no policy exists for action_type' do
    result = Agents::PolicyEvaluator.call(
      action_type: 'unknown_action_type',
      restaurant_id: @restaurant.id,
    )
    assert_equal :require_approval, result
  end

  test 'returns :require_approval when policy is inactive' do
    # inactive_policy fixture has active: false for flag_item_unavailable
    result = Agents::PolicyEvaluator.call(
      action_type: 'flag_item_unavailable',
      restaurant_id: @restaurant.id,
    )
    assert_equal :require_approval, result
  end

  test 'restaurant-scoped policy overrides global default' do
    # Create a global default that says auto_approve
    AgentPolicy.create!(
      restaurant: nil,
      action_type: 'custom_action',
      auto_approve: true,
      active: true,
    )
    # Create a restaurant-scoped override that says require_approval
    AgentPolicy.create!(
      restaurant: @restaurant,
      action_type: 'custom_action',
      auto_approve: false,
      active: true,
    )

    result = Agents::PolicyEvaluator.call(
      action_type: 'custom_action',
      restaurant_id: @restaurant.id,
    )
    assert_equal :require_approval, result
  end
end
