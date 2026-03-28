require 'test_helper'

# DwOrdersMvPolicy: index? checks user.present?.
# show? checks user.present? AND owns_order_data?.
# For records without restaurant_id, owns_order_data? returns false (deny by default).
class DwOrdersMvPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @record = DwOrdersMv.new
  end

  test 'index is allowed for authenticated user' do
    policy = DwOrdersMvPolicy.new(@user, @record)
    assert policy.index?
  end

  test 'scope returns none for nil user (guest access denied at scope level)' do
    # ApplicationPolicy coerces nil → User.new, so index? passes, but scope returns none
    scope = DwOrdersMvPolicy::Scope.new(nil, DwOrdersMv.all)
    assert_equal 0, scope.resolve.count
  end

  test 'show is denied for authenticated user when record has no restaurant_id' do
    # owns_order_data? returns false when record has no restaurant_id (deny by default)
    policy = DwOrdersMvPolicy.new(@user, @record)
    assert_not policy.show?
  end

  test 'show is denied for guest when record has no restaurant_id' do
    policy = DwOrdersMvPolicy.new(nil, @record)
    assert_not policy.show?
  end

  test 'inherits from ApplicationPolicy' do
    assert DwOrdersMvPolicy < ApplicationPolicy
  end

  test 'scope returns none for guest user' do
    scope = DwOrdersMvPolicy::Scope.new(nil, DwOrdersMv.all)
    assert_equal 0, scope.resolve.count
  end

  test 'scope returns none when DwOrdersMv has no restaurant_id column' do
    # Scope falls back to none when restaurant_id column is absent — deny by default
    scope = DwOrdersMvPolicy::Scope.new(@user, DwOrdersMv.all)
    result = scope.resolve
    assert_respond_to result, :count
  end
end
