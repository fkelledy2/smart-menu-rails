# frozen_string_literal: true

require 'test_helper'

class PricingModelPolicyTest < ActiveSupport::TestCase
  def super_admin_user
    users(:one).tap do |u|
      u.admin = true
      u.super_admin = true
    end
  end

  def regular_admin_user
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

  def draft_model
    pricing_models(:draft_2026_q2)
  end

  def published_model
    pricing_models(:legacy_v0)
  end

  test 'super admin can index' do
    policy = PricingModelPolicy.new(super_admin_user, PricingModel)
    assert policy.index?
  end

  test 'regular admin cannot index' do
    policy = PricingModelPolicy.new(regular_admin_user, PricingModel)
    assert_not policy.index?
  end

  test 'regular user cannot index' do
    policy = PricingModelPolicy.new(regular_user, PricingModel)
    assert_not policy.index?
  end

  test 'super admin can edit draft model' do
    policy = PricingModelPolicy.new(super_admin_user, draft_model)
    assert policy.edit?
  end

  test 'super admin cannot edit published model' do
    policy = PricingModelPolicy.new(super_admin_user, published_model)
    assert_not policy.edit?
  end

  test 'super admin can publish draft model' do
    policy = PricingModelPolicy.new(super_admin_user, draft_model)
    assert policy.publish?
  end

  test 'super admin cannot publish published model' do
    policy = PricingModelPolicy.new(super_admin_user, published_model)
    assert_not policy.publish?
  end

  test 'super admin scope returns all models' do
    scope = PricingModelPolicy::Scope.new(super_admin_user, PricingModel).resolve
    assert_equal PricingModel.count, scope.count
  end

  test 'non-super-admin scope returns none' do
    scope = PricingModelPolicy::Scope.new(regular_user, PricingModel).resolve
    assert_equal 0, scope.count
  end
end
