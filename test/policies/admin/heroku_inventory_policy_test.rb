# frozen_string_literal: true

require 'test_helper'

class Admin::HerokuInventoryPolicyTest < ActiveSupport::TestCase
  def super_admin
    users(:one).tap do |u|
      u.admin = true
      u.super_admin = true
    end
  end

  def regular_admin
    users(:one).tap do |u|
      u.admin = true
      u.super_admin = false
    end
  end

  def regular_user
    users(:one).tap do |u|
      u.admin = false
      u.super_admin = false
    end
  end

  test 'super admin can index' do
    policy = Admin::HerokuInventoryPolicy.new(super_admin, :heroku_inventory)
    assert policy.index?
  end

  test 'regular admin cannot index' do
    policy = Admin::HerokuInventoryPolicy.new(regular_admin, :heroku_inventory)
    assert_not policy.index?
  end

  test 'regular user cannot index' do
    policy = Admin::HerokuInventoryPolicy.new(regular_user, :heroku_inventory)
    assert_not policy.index?
  end

  test 'super admin can trigger snapshot' do
    policy = Admin::HerokuInventoryPolicy.new(super_admin, :heroku_inventory)
    assert policy.trigger_snapshot?
  end

  test 'super admin can view coefficients' do
    policy = Admin::HerokuInventoryPolicy.new(super_admin, :heroku_inventory)
    assert policy.coefficients?
  end
end
