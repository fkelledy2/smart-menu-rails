require 'test_helper'

# MetricPolicy:
# All CRUD actions check user.present? (always true via ApplicationPolicy coercion)
# Scope returns scope.all for any caller
class MetricPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @metric = metrics(:one)
  end

  test 'index is allowed for authenticated user' do
    policy = MetricPolicy.new(@owner, @metric)
    assert policy.index?
  end

  test 'index is allowed for nil user (User.new coercion)' do
    policy = MetricPolicy.new(nil, @metric)
    assert policy.index?
  end

  test 'show is allowed for authenticated user' do
    policy = MetricPolicy.new(@owner, @metric)
    assert policy.show?
  end

  test 'create is allowed for authenticated user' do
    policy = MetricPolicy.new(@owner, @metric)
    assert policy.create?
  end

  test 'update is allowed for authenticated user' do
    policy = MetricPolicy.new(@owner, @metric)
    assert policy.update?
  end

  test 'destroy is allowed for authenticated user' do
    policy = MetricPolicy.new(@owner, @metric)
    assert policy.destroy?
  end

  test 'scope returns all records' do
    scope = MetricPolicy::Scope.new(@owner, Metric.all)
    assert_kind_of ActiveRecord::Relation, scope.resolve
  end

  test 'inherits from ApplicationPolicy' do
    assert MetricPolicy < ApplicationPolicy
  end
end
