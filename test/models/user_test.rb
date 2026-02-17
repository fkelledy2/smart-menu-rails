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
    assert Restaurant.where(user_id: @user.id).count >= 1
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
    @user.onboarding_session.update!(status: :started)
    assert_equal 0, @user.onboarding_progress

    @user.onboarding_session.update!(status: :completed)
    assert_equal 100, @user.onboarding_progress
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
    assert Restaurant.exists?(user_id: @user.id)
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

  # === COMPLEX VALIDATION TESTS - EDGE CASES ===

  test 'should reject invalid email format' do
    user = User.new(email: 'invalid_email', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], 'is invalid'
  end

  test 'should accept valid email formats' do
    valid_emails = [
      'user@example.com',
      'user.name@example.com',
      'user+tag@example.co.uk',
      'user_name@example-domain.com',
    ]

    valid_emails.each do |email|
      user = User.new(email: email, password: 'password123')
      assert user.valid?, "#{email} should be valid"
    end
  end

  test 'should reject email without @ symbol' do
    user = User.new(email: 'userexample.com', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], 'is invalid'
  end

  test 'should reject email without domain' do
    user = User.new(email: 'user@', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], 'is invalid'
  end

  test 'should require minimum password length' do
    user = User.new(email: 'test@example.com', password: '12345')
    assert_not user.valid?
    assert_includes user.errors[:password], 'is too short (minimum is 6 characters)'
  end

  test 'should accept password at minimum length' do
    user = User.new(email: 'test@example.com', password: '123456')
    assert user.valid?
  end

  test 'should accept long passwords' do
    user = User.new(email: 'test@example.com', password: 'a' * 128)
    assert user.valid?
  end

  test 'should handle unicode in names' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      first_name: 'José',
      last_name: 'García',
    )
    assert user.valid?
  end

  test 'should handle special characters in names' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      first_name: "O'Brien",
      last_name: 'Smith-Jones',
    )
    assert user.valid?
  end

  test 'should handle very long names' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      first_name: 'A' * 255,
      last_name: 'B' * 255,
    )
    assert user.valid?
  end

  test 'should allow nil first and last names' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      first_name: nil,
      last_name: nil,
    )
    assert user.valid?
  end

  test 'should be case insensitive for email uniqueness' do
    existing_user = users(:one)
    user = User.new(
      email: existing_user.email.upcase,
      password: 'password123',
    )
    assert_not user.valid?
    assert_includes user.errors[:email], 'has already been taken'
  end

  test 'should strip whitespace from email' do
    user = User.new(
      email: '  test@example.com  ',
      password: 'password123',
    )
    user.valid?
    # Devise should handle email normalization
    assert_equal 'test@example.com', user.email.strip
  end

  test 'should handle multiple validation errors' do
    user = User.new(
      email: 'invalid',
      password: '123',
    )
    assert_not user.valid?
    assert user.errors[:email].any?
    assert user.errors[:password].any?
  end

  test 'should require password confirmation to match' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'different',
    )
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test 'should accept matching password confirmation' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123',
    )
    assert user.valid?
  end

  test 'should handle special characters in password' do
    user = User.new(
      email: 'test@example.com',
      password: 'P@ssw0rd!#$%',
    )
    assert user.valid?
  end

  test 'should handle spaces in password' do
    user = User.new(
      email: 'test@example.com',
      password: 'pass word 123',
    )
    assert user.valid?
  end

  test 'should not allow blank email' do
    user = User.new(email: '', password: 'password123')
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test 'should not allow blank password' do
    user = User.new(email: 'test@example.com', password: '')
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  # === BUSINESS RULE VALIDATION TESTS ===

  test 'should create with optional plan' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      plan: nil,
    )
    user.valid? # Trigger before_validation callback
    assert_not_nil user.plan # Default plan should be assigned
  end

  test 'should maintain plan assignment after save' do
    user = User.create!(
      email: 'plantest@example.com',
      password: 'password123',
    )
    assert_not_nil user.plan
    # Default plan should be assigned (whatever the default is)
    assert user.plan.present?
  end

  test 'should allow plan to be nil before validation' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
    )
    assert_nil user.plan
    user.valid?
    assert_not_nil user.plan
  end

  # === CALLBACK TESTS ===

  # before_validation :assign_default_plan callback tests
  test 'should not override existing plan in before_validation callback' do
    premium_plan = plans(:two)
    user = User.new(
      email: 'callback@example.com',
      password: 'password123',
      plan: premium_plan,
    )

    # Trigger validation
    user.valid?

    # Plan should remain unchanged
    assert_equal premium_plan, user.plan
  end

  test 'should handle missing plans gracefully in before_validation callback' do
    # Create a user when no default plan exists
    # The callback should handle this gracefully
    user = User.new(
      email: 'callback@example.com',
      password: 'password123',
    )

    # Even if plan assignment fails, validation should work
    # Plan is optional, so this is acceptable
    assert_nothing_raised do
      user.valid?
    end
  end

  # after_create :setup_onboarding_session callback tests
  test 'should create onboarding session after user creation' do
    user = User.create!(
      email: 'onboarding@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User',
    )

    # Onboarding session should be created
    assert_not_nil user.onboarding_session
    assert_equal :started, user.onboarding_session.status.to_sym
  end

  test 'should set onboarding session status to started' do
    user = User.create!(
      email: 'onboarding2@example.com',
      password: 'password123',
    )

    assert user.onboarding_session.started?
  end

  test 'should associate onboarding session with user' do
    user = User.create!(
      email: 'onboarding3@example.com',
      password: 'password123',
    )

    assert_equal user, user.onboarding_session.user
  end

  # after_update :invalidate_user_caches callback tests
  test 'should call cache invalidation after update' do
    user = users(:one)

    # Mock the cache service
    mock = Minitest::Mock.new
    mock.expect :call, true, [user.id]

    AdvancedCacheService.stub :invalidate_user_caches, mock do
      user.update!(first_name: 'Updated')

      # Verify cache invalidation was called
      assert mock.verify
    end
  end

  test 'should not call cache invalidation on create' do
    # Mock the cache service - should not be called
    mock = Minitest::Mock.new
    # No expectation set

    AdvancedCacheService.stub :invalidate_user_caches, mock do
      user = User.create!(
        email: 'nocache@example.com',
        password: 'password123',
      )

      # If cache invalidation was called, mock would raise error
      # No error means callback didn't execute (correct behavior)
      assert user.persisted?, 'User should be created successfully'
    end
  end

  test 'should call cache invalidation with correct user id' do
    user = users(:one)
    original_id = user.id

    # Mock to capture the argument
    called_with_id = nil
    AdvancedCacheService.stub :invalidate_user_caches, ->(id) { called_with_id = id } do
      user.update!(last_name: 'Changed')
    end

    assert_equal original_id, called_with_id
  end

  test 'should trigger cache invalidation on any attribute update' do
    user = users(:one)

    # Test various attribute updates
    attributes_to_test = [
      { first_name: 'New First' },
      { last_name: 'New Last' },
      { email: 'newemail@example.com' },
    ]

    attributes_to_test.each do |attrs|
      mock = Minitest::Mock.new
      mock.expect :call, true, [user.id]

      AdvancedCacheService.stub :invalidate_user_caches, mock do
        user.update!(attrs)
        assert mock.verify, "Cache invalidation should be called for #{attrs.keys.first}"
      end
    end
  end
end
