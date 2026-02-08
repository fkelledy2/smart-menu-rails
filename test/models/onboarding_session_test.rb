require 'test_helper'

class OnboardingSessionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @session = OnboardingSession.create!(
      user: @user,
      status: :started,
    )
  end

  # Association tests
  test 'belongs to user optionally' do
    assert_respond_to @session, :user
    session = OnboardingSession.new
    assert session.valid?
  end

  test 'belongs to restaurant optionally' do
    assert_respond_to @session, :restaurant
  end

  test 'belongs to menu optionally' do
    assert_respond_to @session, :menu
  end

  # Status enum tests
  test 'has status enum' do
    assert_respond_to @session, :status
    assert_respond_to @session, :started?
    assert_respond_to @session, :completed?
  end

  test 'can transition through statuses' do
    @session.update!(status: :started)
    assert @session.started?

    @session.update!(status: :account_created)
    assert @session.account_created?

    @session.update!(status: :restaurant_details)
    assert @session.restaurant_details?

    @session.update!(status: :plan_selected)
    assert @session.plan_selected?

    @session.update!(status: :menu_created)
    assert @session.menu_created?

    @session.update!(status: :completed)
    assert @session.completed?
  end

  # Wizard data accessors
  test 'can set and get restaurant_name' do
    @session.restaurant_name = 'Test Restaurant'
    assert_equal 'Test Restaurant', @session.restaurant_name
  end

  test 'can set and get restaurant_type' do
    @session.restaurant_type = 'casual_dining'
    assert_equal 'casual_dining', @session.restaurant_type
  end

  test 'can set and get cuisine_type' do
    @session.cuisine_type = 'italian'
    assert_equal 'italian', @session.cuisine_type
  end

  test 'can set and get location' do
    @session.location = 'New York, NY'
    assert_equal 'New York, NY', @session.location
  end

  test 'can set and get phone' do
    @session.phone = '555-1234'
    assert_equal '555-1234', @session.phone
  end

  test 'can set and get selected_plan_id' do
    @session.selected_plan_id = 123
    assert_equal 123, @session.selected_plan_id
  end

  test 'can set and get menu_name' do
    @session.menu_name = 'Lunch Menu'
    assert_equal 'Lunch Menu', @session.menu_name
  end

  test 'can set and get menu_items' do
    items = [{ 'name' => 'Pasta', 'price' => 12.99 }]
    @session.menu_items = items
    assert_equal items, @session.menu_items
  end

  test 'menu_items defaults to empty array' do
    session = OnboardingSession.new
    assert_equal [], session.menu_items
  end

  # Progress calculation
  test 'calculates progress percentage for started' do
    @session.status = :started
    assert_equal 20, @session.progress_percentage
  end

  test 'calculates progress percentage for account_created' do
    @session.status = :account_created
    assert_equal 40, @session.progress_percentage
  end

  test 'calculates progress percentage for restaurant_details' do
    @session.status = :restaurant_details
    assert_equal 60, @session.progress_percentage
  end

  test 'calculates progress percentage for plan_selected' do
    @session.status = :plan_selected
    assert_equal 80, @session.progress_percentage
  end

  test 'calculates progress percentage for menu_created' do
    @session.status = :menu_created
    assert_equal 100, @session.progress_percentage
  end

  test 'calculates progress percentage for completed' do
    @session.status = :completed
    assert_equal 120, @session.progress_percentage
  end

  # Step validation
  test 'step_valid? validates step 1 with user data' do
    @session.user = @user
    assert @session.step_valid?(1)
  end

  test 'step_valid? invalidates step 1 without user' do
    @session.user = nil
    assert_not @session.step_valid?(1)
  end

  test 'step_valid? validates step 2 with restaurant data' do
    @session.restaurant_name = 'Test'
    @session.restaurant_type = 'casual'
    @session.cuisine_type = 'italian'
    assert @session.step_valid?(2)
  end

  test 'step_valid? invalidates step 2 without restaurant data' do
    assert_not @session.step_valid?(2)
  end

  test 'step_valid? validates step 3 with plan' do
    @session.selected_plan_id = 1
    assert @session.step_valid?(3)
  end

  test 'step_valid? invalidates step 3 without plan' do
    assert_not @session.step_valid?(3)
  end

  test 'step_valid? validates step 4 with menu data' do
    @session.menu_name = 'Lunch'
    @session.menu_items = [{ name: 'Pasta' }]
    assert @session.step_valid?(4)
  end

  test 'step_valid? invalidates step 4 without menu data' do
    assert_not @session.step_valid?(4)
  end

  test 'step_valid? returns true for unknown steps' do
    assert @session.step_valid?(99)
  end

  # Persistence
  test 'persists wizard_data' do
    @session.restaurant_name = 'Test Restaurant'
    @session.cuisine_type = 'italian'
    @session.save!

    @session.reload
    assert_equal 'Test Restaurant', @session.restaurant_name
    assert_equal 'italian', @session.cuisine_type
  end

  test 'wizard_data is serialized as JSON' do
    @session.restaurant_name = 'Test'
    @session.save!

    raw_data = @session.read_attribute(:wizard_data)
    assert_kind_of Hash, raw_data
  end
end
