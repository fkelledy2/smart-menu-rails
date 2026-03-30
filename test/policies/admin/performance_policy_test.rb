# frozen_string_literal: true

require 'test_helper'

class Admin::PerformancePolicyTest < ActiveSupport::TestCase
  def setup
    @regular_user = users(:one)
    @admin_user   = users(:admin)
    @record       = Object.new
  end

  # ---------------------------------------------------------------------------
  # All actions require admin?
  # ---------------------------------------------------------------------------

  test 'index? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.index?
  end

  test 'index? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.index?
  end

  test 'index? denied for nil user' do
    policy = Admin::PerformancePolicy.new(nil, @record)
    assert_not policy.index?
  end

  test 'show? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.show?
  end

  test 'show? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.show?
  end

  test 'requests? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.requests?
  end

  test 'requests? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.requests?
  end

  test 'queries? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.queries?
  end

  test 'queries? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.queries?
  end

  test 'cache? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.cache?
  end

  test 'cache? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.cache?
  end

  test 'memory? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.memory?
  end

  test 'memory? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.memory?
  end

  test 'reset? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.reset?
  end

  test 'reset? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.reset?
  end

  test 'export? allowed for admin' do
    policy = Admin::PerformancePolicy.new(@admin_user, @record)
    assert policy.export?
  end

  test 'export? denied for regular user' do
    policy = Admin::PerformancePolicy.new(@regular_user, @record)
    assert_not policy.export?
  end

  test 'all actions denied for nil user' do
    policy = Admin::PerformancePolicy.new(nil, @record)
    %i[index? show? requests? queries? cache? memory? reset? export?].each do |action|
      assert_not policy.public_send(action), "Expected #{action} to be denied for nil user"
    end
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope returns all for admin' do
    scope = Admin::PerformancePolicy::Scope.new(@admin_user, Restaurant.all)
    assert_equal Restaurant.all.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for regular user' do
    scope = Admin::PerformancePolicy::Scope.new(@regular_user, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for nil user' do
    scope = Admin::PerformancePolicy::Scope.new(nil, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'inherits from ApplicationPolicy' do
    assert Admin::PerformancePolicy < ApplicationPolicy
  end
end
