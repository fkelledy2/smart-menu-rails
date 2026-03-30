# frozen_string_literal: true

require 'test_helper'

class ApplicationPolicyTest < ActiveSupport::TestCase
  # ApplicationPolicy is abstract — test via a concrete subclass that doesn't
  # override any methods, so we exercise the base behaviour directly.
  class TestRecord; end # rubocop:disable Lint/EmptyClass

  class ConcretePolicy < ApplicationPolicy; end

  def setup
    @regular_user  = users(:one)
    @admin_user    = users(:admin)
    @super_admin   = users(:super_admin)
    @record        = TestRecord.new
  end

  # ---------------------------------------------------------------------------
  # nil user is coerced to User.new — User.new.present? is TRUE, but
  # ApplicationPolicy base methods all guard on super_admin?, not user.present?
  # ---------------------------------------------------------------------------

  test 'index? denied for regular user' do
    policy = ConcretePolicy.new(@regular_user, @record)
    assert_not policy.index?
  end

  test 'index? denied for nil user (coerced to User.new, not super_admin)' do
    policy = ConcretePolicy.new(nil, @record)
    assert_not policy.index?
  end

  test 'index? allowed for super_admin user' do
    policy = ConcretePolicy.new(@super_admin, @record)
    assert policy.index?
  end

  test 'show? denied for regular user' do
    policy = ConcretePolicy.new(@regular_user, @record)
    assert_not policy.show?
  end

  test 'show? allowed for super_admin user' do
    policy = ConcretePolicy.new(@super_admin, @record)
    assert policy.show?
  end

  test 'create? denied for regular user' do
    policy = ConcretePolicy.new(@regular_user, @record)
    assert_not policy.create?
  end

  test 'create? allowed for super_admin user' do
    policy = ConcretePolicy.new(@super_admin, @record)
    assert policy.create?
  end

  test 'new? delegates to create?' do
    policy = ConcretePolicy.new(@super_admin, @record)
    assert_equal policy.create?, policy.new?
  end

  test 'update? denied for regular user' do
    policy = ConcretePolicy.new(@regular_user, @record)
    assert_not policy.update?
  end

  test 'update? allowed for super_admin user' do
    policy = ConcretePolicy.new(@super_admin, @record)
    assert policy.update?
  end

  test 'edit? delegates to update?' do
    policy = ConcretePolicy.new(@super_admin, @record)
    assert_equal policy.update?, policy.edit?
  end

  test 'destroy? denied for regular user' do
    policy = ConcretePolicy.new(@regular_user, @record)
    assert_not policy.destroy?
  end

  test 'destroy? allowed for super_admin user' do
    policy = ConcretePolicy.new(@super_admin, @record)
    assert policy.destroy?
  end

  test 'admin user without super_admin flag is denied by base policy' do
    # users(:admin) has admin: true but super_admin: false
    policy = ConcretePolicy.new(@admin_user, @record)
    assert_not policy.index?
    assert_not policy.create?
    assert_not policy.destroy?
  end

  # ---------------------------------------------------------------------------
  # Scope — base class raises NotImplementedError for non-super-admin
  # ---------------------------------------------------------------------------

  test 'Scope#resolve returns all records for super_admin' do
    scope = ConcretePolicy::Scope.new(@super_admin, Restaurant.all)
    result = scope.resolve
    assert_equal Restaurant.all.to_sql, result.to_sql
  end

  test 'Scope#resolve raises NotImplementedError for regular user' do
    scope = ConcretePolicy::Scope.new(@regular_user, Restaurant.all)
    assert_raises(NotImplementedError) { scope.resolve }
  end

  test 'Scope#resolve raises NotImplementedError for nil user' do
    scope = ConcretePolicy::Scope.new(nil, Restaurant.all)
    assert_raises(NotImplementedError) { scope.resolve }
  end
end
