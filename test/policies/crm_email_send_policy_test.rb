# frozen_string_literal: true

require 'test_helper'

class CrmEmailSendPolicyTest < ActiveSupport::TestCase
  def setup
    @regular_user  = users(:one)
    @admin_user    = users(:admin)       # admin: true but not @mellow.menu
    @super_admin   = users(:super_admin) # admin: true AND @mellow.menu email
    @record        = Object.new
  end

  # new? and create? are the only direct actions on this policy.

  test 'create? allowed for mellow admin' do
    policy = CrmEmailSendPolicy.new(@super_admin, @record)
    assert policy.create?
  end

  test 'create? denied for plain admin without mellow.menu email' do
    policy = CrmEmailSendPolicy.new(@admin_user, @record)
    assert_not policy.create?
  end

  test 'create? denied for regular user' do
    policy = CrmEmailSendPolicy.new(@regular_user, @record)
    assert_not policy.create?
  end

  test 'create? denied for nil user' do
    policy = CrmEmailSendPolicy.new(nil, @record)
    assert_not policy.create?
  end

  test 'new? delegates to create?' do
    policy = CrmEmailSendPolicy.new(@super_admin, @record)
    assert_equal policy.create?, policy.new?
  end

  test 'new? denied for regular user' do
    policy = CrmEmailSendPolicy.new(@regular_user, @record)
    assert_not policy.new?
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope returns all records for mellow admin' do
    scope = CrmEmailSendPolicy::Scope.new(@super_admin, Restaurant.all)
    assert_equal Restaurant.all.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for regular user' do
    scope = CrmEmailSendPolicy::Scope.new(@regular_user, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for nil user' do
    scope = CrmEmailSendPolicy::Scope.new(nil, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'inherits from ApplicationPolicy' do
    assert CrmEmailSendPolicy < ApplicationPolicy
  end
end
