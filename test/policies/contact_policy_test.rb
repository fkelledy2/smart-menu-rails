require 'test_helper'

class ContactPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @contact = Contact.new
  end

  test "should allow new for any user" do
    policy = ContactPolicy.new(@user, @contact)
    assert policy.new?
  end

  test "should allow new for anonymous user" do
    policy = ContactPolicy.new(nil, @contact)
    assert policy.new?
  end

  test "should allow create for any user" do
    policy = ContactPolicy.new(@user, @contact)
    assert policy.create?
  end

  test "should allow create for anonymous user" do
    policy = ContactPolicy.new(nil, @contact)
    assert policy.create?
  end

  test "should inherit from ApplicationPolicy" do
    assert ContactPolicy < ApplicationPolicy
  end

  test "should handle different contact instances" do
    contact1 = Contact.new(email: 'test1@example.com', message: 'Message 1')
    contact2 = Contact.new(email: 'test2@example.com', message: 'Message 2')
    
    policy1 = ContactPolicy.new(@user, contact1)
    policy2 = ContactPolicy.new(@user, contact2)
    
    assert policy1.new?
    assert policy1.create?
    assert policy2.new?
    assert policy2.create?
  end

  test "should work with different user types" do
    admin_user = users(:one)
    regular_user = users(:two) if users(:two)
    
    # Admin user
    policy = ContactPolicy.new(admin_user, @contact)
    assert policy.new?
    assert policy.create?
    
    # Regular user (if exists)
    if regular_user
      policy = ContactPolicy.new(regular_user, @contact)
      assert policy.new?
      assert policy.create?
    end
  end

  test "should handle edge cases" do
    # Empty contact
    empty_contact = Contact.new
    policy = ContactPolicy.new(@user, empty_contact)
    assert policy.new?
    assert policy.create?
    
    # Contact with data
    filled_contact = Contact.new(email: 'test@example.com', message: 'Test message')
    policy = ContactPolicy.new(@user, filled_contact)
    assert policy.new?
    assert policy.create?
  end
end
