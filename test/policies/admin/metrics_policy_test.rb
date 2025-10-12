require 'test_helper'

class Admin::MetricsPolicyTest < ActiveSupport::TestCase
  def setup
    @regular_user = users(:one)
    @other_user = users(:two)
    @metric = Metric.create!(
      numberOfRestaurants: 10,
      numberOfMenus: 25,
      numberOfMenuItems: 150,
      numberOfOrders: 500,
      totalOrderValue: 12500.50
    )
  end

  def create_admin_user
    User.create!(
      email: 'admin@example.com',
      password: 'password123',
      admin: true
    )
  end

  # === INDEX TESTS ===
  
  test "should allow admin user to view metrics index" do
    admin_user = create_admin_user
    policy = Admin::MetricsPolicy.new(admin_user, Metric)
    assert policy.index?
  end

  test "should deny regular user from viewing metrics index" do
    policy = Admin::MetricsPolicy.new(@regular_user, Metric)
    assert_not policy.index?
  end

  test "should deny anonymous user from viewing metrics index" do
    policy = Admin::MetricsPolicy.new(nil, Metric)
    assert_not policy.index?
  end

  # === SHOW TESTS ===
  
  test "should allow admin user to view metric" do
    admin_user = create_admin_user
    policy = Admin::MetricsPolicy.new(admin_user, @metric)
    assert policy.show?
  end

  test "should deny regular user from viewing metric" do
    policy = Admin::MetricsPolicy.new(@regular_user, @metric)
    assert_not policy.show?
  end

  test "should deny anonymous user from viewing metric" do
    policy = Admin::MetricsPolicy.new(nil, @metric)
    assert_not policy.show?
  end

  # === EXPORT TESTS ===
  
  test "should allow admin user to export metrics" do
    admin_user = create_admin_user
    policy = Admin::MetricsPolicy.new(admin_user, @metric)
    assert policy.export?
  end

  test "should deny regular user from exporting metrics" do
    policy = Admin::MetricsPolicy.new(@regular_user, @metric)
    assert_not policy.export?
  end

  test "should deny anonymous user from exporting metrics" do
    policy = Admin::MetricsPolicy.new(nil, @metric)
    assert_not policy.export?
  end

  # === SCOPE TESTS ===
  
  test "should return all metrics for admin user" do
    admin_user = create_admin_user
    scope = Admin::MetricsPolicy::Scope.new(admin_user, Metric).resolve
    
    # Admin should have access to all metrics
    assert_equal Metric.all.to_sql, scope.to_sql
  end

  test "should return no metrics for regular user" do
    scope = Admin::MetricsPolicy::Scope.new(@regular_user, Metric).resolve
    
    # Regular user should have no access to metrics
    assert_equal Metric.none.to_sql, scope.to_sql
  end

  test "should return no metrics for anonymous user" do
    scope = Admin::MetricsPolicy::Scope.new(nil, Metric).resolve
    
    # Anonymous user should have no access to metrics
    assert_equal Metric.none.to_sql, scope.to_sql
  end

  # === EDGE CASE TESTS ===
  
  test "should handle nil metric record" do
    admin_user = create_admin_user
    policy = Admin::MetricsPolicy.new(admin_user, nil)
    
    # Admin should still have permissions even with nil record
    assert policy.show?
    assert policy.export?
  end

  test "should handle user without admin attribute" do
    user_without_admin = User.new(email: 'test@example.com')
    policy = Admin::MetricsPolicy.new(user_without_admin, @metric)
    
    # User without admin attribute should be denied
    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.export?
  end

  test "should inherit from ApplicationPolicy" do
    assert Admin::MetricsPolicy < ApplicationPolicy
  end

  # === ADMIN ATTRIBUTE TESTS ===
  
  test "should properly check admin attribute" do
    # Test with explicitly non-admin user
    non_admin = User.create!(
      email: 'nonadmin@example.com',
      password: 'password123',
      admin: false
    )
    
    policy = Admin::MetricsPolicy.new(non_admin, @metric)
    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.export?
    
    # Test with explicitly admin user
    admin = User.create!(
      email: 'admin2@example.com',
      password: 'password123',
      admin: true
    )
    
    admin_policy = Admin::MetricsPolicy.new(admin, @metric)
    assert admin_policy.index?
    assert admin_policy.show?
    assert admin_policy.export?
  end

  # === SECURITY TESTS ===
  
  test "should consistently deny access to non-admin users across all methods" do
    non_admin_users = [@regular_user, @other_user, nil]
    
    non_admin_users.each do |user|
      policy = Admin::MetricsPolicy.new(user, @metric)
      
      assert_not policy.index?, "#{user&.email || 'anonymous'} should not have index access"
      assert_not policy.show?, "#{user&.email || 'anonymous'} should not have show access"
      assert_not policy.export?, "#{user&.email || 'anonymous'} should not have export access"
      
      scope = Admin::MetricsPolicy::Scope.new(user, Metric).resolve
      assert_equal Metric.none.to_sql, scope.to_sql, "#{user&.email || 'anonymous'} should have empty scope"
    end
  end

  test "should consistently allow access to admin users across all methods" do
    admin_user = create_admin_user
    policy = Admin::MetricsPolicy.new(admin_user, @metric)
    
    assert policy.index?, "Admin should have index access"
    assert policy.show?, "Admin should have show access"
    assert policy.export?, "Admin should have export access"
    
    scope = Admin::MetricsPolicy::Scope.new(admin_user, Metric).resolve
    assert_equal Metric.all.to_sql, scope.to_sql, "Admin should have full scope access"
  end

  # === BUSINESS LOGIC TESTS ===
  
  test "should handle multiple admin users" do
    admin1 = User.create!(email: 'admin1@example.com', password: 'password123', admin: true)
    admin2 = User.create!(email: 'admin2@example.com', password: 'password123', admin: true)
    
    policy1 = Admin::MetricsPolicy.new(admin1, @metric)
    policy2 = Admin::MetricsPolicy.new(admin2, @metric)
    
    # Both admins should have the same permissions
    assert policy1.index?
    assert policy2.index?
    assert policy1.show?
    assert policy2.show?
    assert policy1.export?
    assert policy2.export?
  end

  test "should handle admin status changes" do
    user = User.create!(
      email: 'changeable@example.com',
      password: 'password123',
      admin: false
    )
    
    # Initially not admin
    policy = Admin::MetricsPolicy.new(user, @metric)
    assert_not policy.index?
    
    # After becoming admin
    user.update!(admin: true)
    user.reload
    admin_policy = Admin::MetricsPolicy.new(user, @metric)
    assert admin_policy.index?
    
    # After losing admin status
    user.update!(admin: false)
    user.reload
    non_admin_policy = Admin::MetricsPolicy.new(user, @metric)
    assert_not non_admin_policy.index?
  end
end
