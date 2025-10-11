require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @plan = plans(:one)
  end

  # Association tests
  test 'should belong to plan' do
    assert_respond_to @user, :plan
  end

  test 'should have many restaurants' do
    assert_respond_to @user, :restaurants
    assert @user.restaurants.count >= 1
  end

  test 'should have one onboarding session' do
    assert_respond_to @user, :onboarding_session
    assert_not_nil @user.onboarding_session
  end

  test 'should have many notifications' do
    assert_respond_to @user, :notifications
  end

  test 'should have one attached avatar' do
    assert_respond_to @user, :avatar
  end

  # Validation tests
  test 'should be valid with valid attributes' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      first_name: 'John',
      last_name: 'Doe',
    )
    assert user.valid?
  end

  test 'should require email' do
    user = User.new(password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test 'should require password' do
    user = User.new(email: 'test@example.com')
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test 'should require unique email' do
    existing_user = users(:one)
    user = User.new(
      email: existing_user.email,
      password: 'password123',
    )
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  # Business logic tests
  test 'onboarding_complete? should return true when onboarding is completed' do
    @user.onboarding_session.update!(status: :completed)
    assert @user.onboarding_complete?
  end

  test 'onboarding_complete? should return false when onboarding is not completed' do
    @user.onboarding_session.update!(status: :started)
    assert_not @user.onboarding_complete?
  end

  test 'onboarding_complete? should return false when no onboarding session' do
    @user.onboarding_session.destroy!
    @user.reload
    assert_not @user.onboarding_complete?
  end

  test 'onboarding_progress should return progress percentage' do
    @user.onboarding_session.update!(status: :restaurant_details)
    assert_equal 60, @user.onboarding_progress # restaurant_details is step 2, so (2+1)*20 = 60%
  end

  test 'onboarding_progress should return 0 when no onboarding session' do
    @user.onboarding_session.destroy!
    @user.reload
    assert_equal 0, @user.onboarding_progress
  end

  test 'needs_onboarding? should return true when not complete and no restaurants' do
    # Create a new user without restaurants to avoid foreign key constraints
    user = User.create!(
      email: 'norestaurants@example.com',
      password: 'password123',
      first_name: 'No',
      last_name: 'Restaurants',
    )
    user.onboarding_session.update!(status: :started)
    assert user.needs_onboarding?
  end

  test 'needs_onboarding? should return false when onboarding complete' do
    @user.onboarding_session.update!(status: :completed)
    assert_not @user.needs_onboarding?
  end

  test 'needs_onboarding? should return false when has restaurants' do
    @user.onboarding_session.update!(status: :started)
    assert @user.restaurants.any?
    assert_not @user.needs_onboarding?
  end

  # Name handling tests
  test 'name should return full name' do
    @user.first_name = 'John'
    @user.last_name = 'Doe'
    assert_equal 'John Doe', @user.name
  end

  test 'name should handle missing last name' do
    @user.first_name = 'John'
    @user.last_name = nil
    assert_equal 'John', @user.name
  end

  test 'name should handle missing first name' do
    @user.first_name = nil
    @user.last_name = 'Doe'
    assert_equal 'Doe', @user.name
  end

  test 'name= should split full name correctly' do
    @user.name = 'Jane Smith'
    assert_equal 'Jane', @user.first_name
    assert_equal 'Smith', @user.last_name
  end

  test 'name= should handle single name' do
    user = User.new
    user.name = 'Madonna'
    assert_equal 'Madonna', user.first_name
    assert_nil user.last_name
  end

  test 'name= should handle empty string' do
    user = User.new
    user.name = ''
    assert_nil user.first_name
    assert_nil user.last_name
  end

  # Callback tests
  test 'should create onboarding session after create' do
    user = User.create!(
      email: 'newuser@example.com',
      password: 'password123',
      first_name: 'New',
      last_name: 'User',
    )

    assert_not_nil user.onboarding_session
    assert_equal :started, user.onboarding_session.status.to_sym
  end

  test 'should assign default plan before validation on create' do
    user = User.new(
      email: 'newuser@example.com',
      password: 'password123',
    )

    user.valid? # Trigger validations
    assert_not_nil user.plan
  end

  test 'should not override existing plan' do
    premium_plan = plans(:two)
    user = User.new(
      email: 'newuser@example.com',
      password: 'password123',
      plan: premium_plan,
    )

    user.valid? # Trigger validations
    assert_equal premium_plan, user.plan
  end

  # Dependent destroy tests
  test 'should have dependent destroy associations configured' do
    # Test that the associations are configured correctly without actually destroying
    # to avoid foreign key constraint issues in test environment
    assert_equal :destroy, User.reflect_on_association(:restaurants).options[:dependent]
    assert_equal :destroy, User.reflect_on_association(:onboarding_session).options[:dependent]
  end
end
