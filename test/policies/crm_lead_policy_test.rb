# frozen_string_literal: true

require 'test_helper'

class CrmLeadPolicyTest < ActiveSupport::TestCase
  def setup
    @regular_user  = users(:one)
    @admin_user    = users(:admin)         # admin: true but NOT @mellow.menu
    @super_admin   = users(:super_admin)   # admin: true AND email ends with @mellow.menu
    @record        = Object.new            # CrmLead record (structure irrelevant for these tests)
  end

  # ---------------------------------------------------------------------------
  # mellow_admin? = admin? AND email ends with @mellow.menu
  # Only super_admin fixture qualifies in the standard fixture set.
  # ---------------------------------------------------------------------------

  test 'index? denied for regular user' do
    policy = CrmLeadPolicy.new(@regular_user, @record)
    assert_not policy.index?
  end

  test 'index? denied for admin without mellow.menu email' do
    policy = CrmLeadPolicy.new(@admin_user, @record)
    assert_not policy.index?
  end

  test 'index? denied for nil user' do
    policy = CrmLeadPolicy.new(nil, @record)
    assert_not policy.index?
  end

  test 'index? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.index?
  end

  test 'show? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.show?
  end

  test 'show? denied for regular user' do
    policy = CrmLeadPolicy.new(@regular_user, @record)
    assert_not policy.show?
  end

  test 'create? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.create?
  end

  test 'create? denied for regular user' do
    policy = CrmLeadPolicy.new(@regular_user, @record)
    assert_not policy.create?
  end

  test 'new? delegates to create?' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert_equal policy.create?, policy.new?
  end

  test 'update? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.update?
  end

  test 'update? denied for regular user' do
    policy = CrmLeadPolicy.new(@regular_user, @record)
    assert_not policy.update?
  end

  test 'edit? delegates to update?' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert_equal policy.update?, policy.edit?
  end

  test 'destroy? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.destroy?
  end

  test 'destroy? denied for regular user' do
    policy = CrmLeadPolicy.new(@regular_user, @record)
    assert_not policy.destroy?
  end

  test 'transition? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.transition?
  end

  test 'convert? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.convert?
  end

  test 'reopen? allowed for mellow admin' do
    policy = CrmLeadPolicy.new(@super_admin, @record)
    assert policy.reopen?
  end

  test 'all actions denied for non-mellow admin user' do
    policy = CrmLeadPolicy.new(@admin_user, @record)
    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.transition?
    assert_not policy.convert?
    assert_not policy.reopen?
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope resolves all for mellow admin' do
    # We use a simple array-backed object — just verify the all path executes
    # by using a real AR model the scope can call .all on.
    scope = CrmLeadPolicy::Scope.new(@super_admin, Restaurant.all)
    result = scope.resolve
    assert_equal Restaurant.all.to_sql, result.to_sql
  end

  test 'scope returns none for regular user' do
    scope = CrmLeadPolicy::Scope.new(@regular_user, Restaurant.all)
    result = scope.resolve
    assert_equal Restaurant.none.to_sql, result.to_sql
  end

  test 'scope returns none for nil user' do
    scope = CrmLeadPolicy::Scope.new(nil, Restaurant.all)
    result = scope.resolve
    assert_equal Restaurant.none.to_sql, result.to_sql
  end
end
