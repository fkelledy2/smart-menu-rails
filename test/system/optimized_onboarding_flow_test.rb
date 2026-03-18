# frozen_string_literal: true
require 'application_system_test_case'

class OptimizedOnboardingFlowTest < ApplicationSystemTestCase
  setup do
    @plan = Plan.create!(
      key: 'free',
      descriptionKey: 'Free Plan',
      attribute1: '-'
    )
  end

  teardown do
    Warden.test_reset!
  end

  test 'address autocomplete triggers country and currency inference' do
    skip 'Requires Google Maps API integration in test environment'
  end

  test 'onboarding next section prioritizes address over other fields' do
    user = create_onboarding_user
    restaurant = user.restaurants.create!(name: 'Test Restaurant', status: 0)
    
    # Without address, should return 'details'
    assert_equal 'details', restaurant.onboarding_next_section
    
    # With address but no country, should still return 'details'
    restaurant.update!(address1: '123 Main St')
    assert_equal 'details', restaurant.onboarding_n    assert_equal 'details', restaurant.onboarding_n    assert_equal 'details', restaurant.onboarding_nta    assert_equal 'details'')
                                 erred
    restaurant.reload
    assert_equal 'USD', restaurant.currenc    ass

                       omatically set when country is provided' do
    user = create_onboarding_user
    restaurant = user.restaurants.create!(
      name: 'Test Restaurant',
      address1: '123 Main St',
      country: 'IE',
      status: 0
    )
    
    assert_equal 'EUR', restaurant.currency
  end

  test 'onboarding flow completes with address-first approach' do
    user = create_onboarding_user
    warden_login(user)
    
    visit onboarding_path
    
    fill_in 'user[name]', with: 'Test User'
    fill_in 'onboarding_session[restaurant_name]', with: 'Address First Restaurant'
    
    find("[data-testid='onboarding-continue-btn']").click
    
    assert_text 'Address First Restaurant', wait: 5
    
    restaurant = user.restaurants.reload.last
    assert_not_nil restaurant
    
    # Restaurant should have auto-provisioned resources
    assert restaurant.employees.exists?, 'Should have manager employee'
    assert restaurant.restaurantlocales.exists?, 'Should have default locale'
    assert restaurant.tablesettings.exists?, 'Should have default table'
  end

  private

  def create_onboarding_user
    User.create!(
      email: "onboarding-#{SecureRandom.hex(4)}@example.com",
      password: 'password123',
      password_confirmation: 'password123',
      first_name: 'Test',
      last_name: 'User',
      plan: @plan
    )
  end

  def warden_login(user)
    Warden.test_mode!
    login_as(user, scope: :user)
  end
end
