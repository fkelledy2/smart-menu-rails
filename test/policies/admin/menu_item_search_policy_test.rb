# frozen_string_literal: true

require 'test_helper'

class Admin::MenuItemSearchPolicyTest < ActiveSupport::TestCase
  def setup
    @regular_user = users(:one)
    @admin_user   = users(:admin)
    @record       = Object.new
  end

  test 'index? allowed for admin' do
    policy = Admin::MenuItemSearchPolicy.new(@admin_user, @record)
    assert policy.index?
  end

  test 'index? denied for regular user' do
    policy = Admin::MenuItemSearchPolicy.new(@regular_user, @record)
    assert_not policy.index?
  end

  test 'index? denied for nil user' do
    policy = Admin::MenuItemSearchPolicy.new(nil, @record)
    assert_not policy.index?
  end

  test 'reindex? allowed for admin' do
    policy = Admin::MenuItemSearchPolicy.new(@admin_user, @record)
    assert policy.reindex?
  end

  test 'reindex? denied for regular user' do
    policy = Admin::MenuItemSearchPolicy.new(@regular_user, @record)
    assert_not policy.reindex?
  end

  test 'reindex? denied for nil user' do
    policy = Admin::MenuItemSearchPolicy.new(nil, @record)
    assert_not policy.reindex?
  end

  test 'inherits from ApplicationPolicy' do
    assert Admin::MenuItemSearchPolicy < ApplicationPolicy
  end
end
