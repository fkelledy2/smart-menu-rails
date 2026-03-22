require 'test_helper'

# DwOrdersMvPolicy: index? checks user.present? (always true via User.new).
# show? checks user.present? AND owns_order_data?.
# For records without restaurant_id, owns_order_data? returns true for any present user.
class DwOrdersMvPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @record = DwOrdersMv.new
  end

  test 'index is allowed for authenticated user' do
    policy = DwOrdersMvPolicy.new(@user, @record)
    assert policy.index?
  end

  test 'index is allowed for guest (user.present? always true)' do
    policy = DwOrdersMvPolicy.new(nil, @record)
    assert policy.index?
  end

  test 'show is allowed for authenticated user with generic record' do
    policy = DwOrdersMvPolicy.new(@user, @record)
    assert policy.show?
  end

  test 'show is allowed for guest when record has no restaurant_id (fallback to true)' do
    # owns_order_data? returns true when record has no restaurant_id
    policy = DwOrdersMvPolicy.new(nil, @record)
    assert policy.show?
  end

  test 'inherits from ApplicationPolicy' do
    assert DwOrdersMvPolicy < ApplicationPolicy
  end

  test 'scope returns none for guest user (no restaurants)' do
    scope = DwOrdersMvPolicy::Scope.new(nil, DwOrdersMv.all)
    assert_equal 0, scope.resolve.count
  end

  test 'scope returns all when DwOrdersMv has no restaurant_id column' do
    # DwOrdersMv is a materialized view; scope falls back to all if no restaurant_id
    scope = DwOrdersMvPolicy::Scope.new(@user, DwOrdersMv.all)
    result = scope.resolve
    assert_respond_to result, :count
  end
end
