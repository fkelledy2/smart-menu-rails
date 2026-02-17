# frozen_string_literal: true

require 'application_system_test_case'

# System tests for the simplified single-step onboarding flow.
# New user → /onboarding → enter name + restaurant name → redirect to restaurant edit
class OnboardingFlowTest < ApplicationSystemTestCase
  setup do
    @plan = Plan.create!(
      key: 'free',
      descriptionKey: 'Free Plan',
      attribute1: '-',
    )
  end

  teardown do
    Warden.test_reset!
  end

  # ===================
  # PAGE STRUCTURE TESTS
  # ===================

  test 'onboarding page displays form with name and restaurant name fields' do
    user = create_onboarding_user
    warden_login(user)

    visit onboarding_path

    assert_selector "[data-testid='onboarding-account-form']"
    assert_selector "[data-testid='onboarding-user-name']"
    assert_selector "[data-testid='restaurant-name']"
    assert_selector "[data-testid='onboarding-continue-btn']"
  end

  test 'continue button is disabled until both fields are filled' do
    user = create_onboarding_user
    warden_login(user)

    visit onboarding_path

    btn = find("[data-testid='onboarding-continue-btn']")
    assert btn.disabled?, 'Continue button should be disabled initially'

    # Fill only name — still disabled
    fill_in 'user[name]', with: 'Test User'
    assert btn.disabled?, 'Continue button should be disabled with only name'

    # Fill restaurant name — should enable
    fill_in 'onboarding_session[restaurant_name]', with: 'My Restaurant'
    assert_not btn.disabled?, 'Continue button should be enabled when both fields filled'
  end

  # ===================
  # SUCCESSFUL ONBOARDING
  # ===================

  test 'completing onboarding creates restaurant and redirects to restaurant edit' do
    user = create_onboarding_user
    warden_login(user)

    visit onboarding_path

    fill_in 'user[name]', with: 'Fergus Kelledy'
    fill_in 'onboarding_session[restaurant_name]', with: 'The Test Kitchen'

    find("[data-testid='onboarding-continue-btn']").click

    # Should redirect to restaurant edit page
    assert_text 'The Test Kitchen', wait: 5

    # Restaurant should be created
    restaurant = user.restaurants.reload.last
    assert_not_nil restaurant
    assert_equal 'The Test Kitchen', restaurant.name

    # Onboarding should be completed
    user.reload
    assert user.onboarding_complete?
  end

  # ===================
  # REDIRECT TESTS
  # ===================

  test 'user with existing restaurant skips onboarding' do
    user = create_onboarding_user
    restaurant = user.restaurants.create!(name: 'Existing Place', archived: false, status: 0)
    user.onboarding_session.update!(status: :completed, restaurant: restaurant)
    warden_login(user)

    visit onboarding_path

    # Should redirect away from onboarding (to restaurant edit)
    assert_no_selector "[data-testid='onboarding-account-form']"
  end

  test 'user who completed onboarding is not redirected back' do
    user = create_onboarding_user
    restaurant = user.restaurants.create!(name: 'Done Place', archived: false, status: 0)
    user.onboarding_session.update!(status: :completed, restaurant: restaurant)
    warden_login(user)

    # Visiting the restaurant edit page should work normally
    visit edit_restaurant_path(restaurant)

    assert_text 'Done Place', wait: 5
  end

  # ===================
  # UNAUTHENTICATED ACCESS
  # ===================

  test 'unauthenticated user is redirected to login' do
    visit onboarding_path

    # Should redirect to login page
    assert_selector "[data-testid='login-card']", wait: 5
  end

  private

  # User.after_create :setup_onboarding_session creates the session automatically
  def create_onboarding_user
    User.create!(
      email: "onboarding-#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Test',
      last_name: 'User',
      plan: @plan,
    )
  end

  def warden_login(user)
    Warden.test_mode!
    login_as(user, scope: :user)
  end
end
