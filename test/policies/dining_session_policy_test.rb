require 'test_helper'

class DiningSessionPolicyTest < ActiveSupport::TestCase
  def setup
    @owner = users(:one)
    @other_user = users(:two)
    @dining_session = dining_sessions(:valid_session) # belongs to restaurant :one → user :one
  end

  # create? — always true (public QR flow)
  test 'create is allowed for anyone including guests' do
    assert DiningSessionPolicy.new(nil, @dining_session).create?
    assert DiningSessionPolicy.new(@owner, @dining_session).create?
    assert DiningSessionPolicy.new(@other_user, @dining_session).create?
  end

  # show? — owner only
  test 'show is allowed for restaurant owner' do
    assert DiningSessionPolicy.new(@owner, @dining_session).show?
  end

  test 'show is denied for non-owner' do
    assert_not DiningSessionPolicy.new(@other_user, @dining_session).show?
  end

  test 'show is denied for guest' do
    assert_not DiningSessionPolicy.new(nil, @dining_session).show?
  end

  # index? — owner only
  test 'index is allowed for restaurant owner' do
    assert DiningSessionPolicy.new(@owner, @dining_session).index?
  end

  test 'index is denied for non-owner' do
    assert_not DiningSessionPolicy.new(@other_user, @dining_session).index?
  end

  # destroy? — owner only
  test 'destroy is allowed for restaurant owner' do
    assert DiningSessionPolicy.new(@owner, @dining_session).destroy?
  end

  test 'destroy is denied for non-owner' do
    assert_not DiningSessionPolicy.new(@other_user, @dining_session).destroy?
  end

  # Scope
  test 'scope returns sessions for restaurants owned by user' do
    scope = DiningSessionPolicy::Scope.new(@owner, DiningSession).resolve
    restaurant_ids = restaurants(:one).id
    assert scope.all? { |ds| ds.restaurant_id == restaurant_ids }
  end

  test 'scope returns all sessions for super_admin' do
    admin = users(:one)
    admin.stub(:super_admin?, true) do
      scope = DiningSessionPolicy::Scope.new(admin, DiningSession).resolve
      assert_equal DiningSession.count, scope.count
    end
  end
end
