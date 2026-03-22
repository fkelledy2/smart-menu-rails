require 'test_helper'

# AnalyticsPolicy:
# track?         — user.present? (always true via User.new coercion)
# track_anonymous? — always true
class AnalyticsPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @record = :analytics # policy does not operate on a real record
  end

  test 'track is allowed for authenticated user' do
    policy = AnalyticsPolicy.new(@owner, @record)
    assert policy.track?
  end

  test 'track is allowed for nil user (ApplicationPolicy converts nil to User.new)' do
    policy = AnalyticsPolicy.new(nil, @record)
    assert policy.track?
  end

  test 'track_anonymous is always true' do
    policy = AnalyticsPolicy.new(nil, @record)
    assert policy.track_anonymous?
  end

  test 'track_anonymous is true for authenticated user' do
    policy = AnalyticsPolicy.new(@owner, @record)
    assert policy.track_anonymous?
  end

  test 'inherits from ApplicationPolicy' do
    assert AnalyticsPolicy < ApplicationPolicy
  end
end
