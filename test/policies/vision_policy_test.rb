require 'test_helper'

# VisionPolicy: analyze? and detect_menu_items? check user.present?.
# ApplicationPolicy converts nil -> User.new so user.present? is always true.
# Both actions are effectively open to any caller that passes the policy.
class VisionPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @record = Object.new
  end

  test 'analyze is allowed for authenticated user' do
    policy = VisionPolicy.new(@user, @record)
    assert policy.analyze?
  end

  test 'analyze is allowed for guest (user.present? is always true)' do
    policy = VisionPolicy.new(nil, @record)
    assert policy.analyze?
  end

  test 'detect_menu_items is allowed for authenticated user' do
    policy = VisionPolicy.new(@user, @record)
    assert policy.detect_menu_items?
  end

  test 'detect_menu_items is allowed for guest (user.present? is always true)' do
    policy = VisionPolicy.new(nil, @record)
    assert policy.detect_menu_items?
  end

  test 'inherits from ApplicationPolicy' do
    assert VisionPolicy < ApplicationPolicy
  end
end
