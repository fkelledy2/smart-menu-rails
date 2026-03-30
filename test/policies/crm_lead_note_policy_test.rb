# frozen_string_literal: true

require 'test_helper'

class CrmLeadNotePolicyTest < ActiveSupport::TestCase
  def setup
    @regular_user  = users(:one)
    @admin_user    = users(:admin)       # admin: true but not @mellow.menu email
    @super_admin   = users(:super_admin) # admin: true AND @mellow.menu email
    @record        = Object.new
  end

  # create? and destroy? are the only direct actions on this policy.

  test 'create? allowed for mellow admin' do
    policy = CrmLeadNotePolicy.new(@super_admin, @record)
    assert policy.create?
  end

  test 'create? denied for plain admin without mellow.menu email' do
    policy = CrmLeadNotePolicy.new(@admin_user, @record)
    assert_not policy.create?
  end

  test 'create? denied for regular user' do
    policy = CrmLeadNotePolicy.new(@regular_user, @record)
    assert_not policy.create?
  end

  test 'create? denied for nil user' do
    policy = CrmLeadNotePolicy.new(nil, @record)
    assert_not policy.create?
  end

  test 'destroy? allowed for mellow admin' do
    policy = CrmLeadNotePolicy.new(@super_admin, @record)
    assert policy.destroy?
  end

  test 'destroy? denied for regular user' do
    policy = CrmLeadNotePolicy.new(@regular_user, @record)
    assert_not policy.destroy?
  end

  test 'destroy? denied for nil user' do
    policy = CrmLeadNotePolicy.new(nil, @record)
    assert_not policy.destroy?
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope returns all records for mellow admin' do
    scope = CrmLeadNotePolicy::Scope.new(@super_admin, Restaurant.all)
    assert_equal Restaurant.all.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for regular user' do
    scope = CrmLeadNotePolicy::Scope.new(@regular_user, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for nil user' do
    scope = CrmLeadNotePolicy::Scope.new(nil, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'inherits from ApplicationPolicy' do
    assert CrmLeadNotePolicy < ApplicationPolicy
  end
end
