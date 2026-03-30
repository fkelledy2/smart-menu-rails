# frozen_string_literal: true

require 'test_helper'

class Admin::CachePolicyTest < ActiveSupport::TestCase
  def setup
    @regular_user = users(:one)
    @admin_user   = users(:admin)
    @record       = Object.new
  end

  # ---------------------------------------------------------------------------
  # All actions require admin? — nil user becomes User.new (not admin)
  # ---------------------------------------------------------------------------

  test 'index? allowed for admin user' do
    policy = Admin::CachePolicy.new(@admin_user, @record)
    assert policy.index?
  end

  test 'index? denied for regular user' do
    policy = Admin::CachePolicy.new(@regular_user, @record)
    assert_not policy.index?
  end

  test 'index? denied for nil user' do
    policy = Admin::CachePolicy.new(nil, @record)
    assert_not policy.index?
  end

  test 'stats? allowed for admin' do
    policy = Admin::CachePolicy.new(@admin_user, @record)
    assert policy.stats?
  end

  test 'stats? denied for regular user' do
    policy = Admin::CachePolicy.new(@regular_user, @record)
    assert_not policy.stats?
  end

  test 'warm? allowed for admin' do
    policy = Admin::CachePolicy.new(@admin_user, @record)
    assert policy.warm?
  end

  test 'warm? denied for regular user' do
    policy = Admin::CachePolicy.new(@regular_user, @record)
    assert_not policy.warm?
  end

  test 'clear? allowed for admin' do
    policy = Admin::CachePolicy.new(@admin_user, @record)
    assert policy.clear?
  end

  test 'clear? denied for regular user' do
    policy = Admin::CachePolicy.new(@regular_user, @record)
    assert_not policy.clear?
  end

  test 'reset_stats? allowed for admin' do
    policy = Admin::CachePolicy.new(@admin_user, @record)
    assert policy.reset_stats?
  end

  test 'reset_stats? denied for regular user' do
    policy = Admin::CachePolicy.new(@regular_user, @record)
    assert_not policy.reset_stats?
  end

  test 'health? allowed for admin' do
    policy = Admin::CachePolicy.new(@admin_user, @record)
    assert policy.health?
  end

  test 'health? denied for regular user' do
    policy = Admin::CachePolicy.new(@regular_user, @record)
    assert_not policy.health?
  end

  test 'keys? allowed for admin' do
    policy = Admin::CachePolicy.new(@admin_user, @record)
    assert policy.keys?
  end

  test 'keys? denied for regular user' do
    policy = Admin::CachePolicy.new(@regular_user, @record)
    assert_not policy.keys?
  end

  test 'all actions denied for nil user' do
    policy = Admin::CachePolicy.new(nil, @record)
    assert_not policy.index?
    assert_not policy.stats?
    assert_not policy.warm?
    assert_not policy.clear?
    assert_not policy.reset_stats?
    assert_not policy.health?
    assert_not policy.keys?
  end

  # ---------------------------------------------------------------------------
  # Scope
  # ---------------------------------------------------------------------------

  test 'scope returns all for admin user' do
    scope = Admin::CachePolicy::Scope.new(@admin_user, Restaurant.all)
    assert_equal Restaurant.all.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for regular user' do
    scope = Admin::CachePolicy::Scope.new(@regular_user, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'scope returns none for nil user' do
    scope = Admin::CachePolicy::Scope.new(nil, Restaurant.all)
    assert_equal Restaurant.none.to_sql, scope.resolve.to_sql
  end

  test 'inherits from ApplicationPolicy' do
    assert Admin::CachePolicy < ApplicationPolicy
  end
end
