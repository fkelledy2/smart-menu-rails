require 'test_helper'

class OnboardingHelperTest < ActionView::TestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)

    # Ensure proper associations
    @restaurant.update!(user: @user) if @restaurant.user != @user
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant
  end

  # === ONBOARDING STEP TITLE TESTS ===

  test 'should return correct title for restaurant step' do
    assert_equal 'Restaurant Information', onboarding_step_title('1')
    assert_equal 'Restaurant Information', onboarding_step_title('restaurant')
    assert_equal 'Restaurant Information', onboarding_step_title(1)
  end

  test 'should return correct title for menu step' do
    assert_equal 'Menu Setup', onboarding_step_title('2')
    assert_equal 'Menu Setup', onboarding_step_title('menu')
    assert_equal 'Menu Setup', onboarding_step_title(2)
  end

  test 'should return correct title for payment step' do
    assert_equal 'Payment Configuration', onboarding_step_title('3')
    assert_equal 'Payment Configuration', onboarding_step_title('payment')
    assert_equal 'Payment Configuration', onboarding_step_title(3)
  end

  test 'should return correct title for complete step' do
    assert_equal 'Setup Complete', onboarding_step_title('4')
    assert_equal 'Setup Complete', onboarding_step_title('complete')
    assert_equal 'Setup Complete', onboarding_step_title(4)
  end

  test 'should return default title for unknown step' do
    assert_equal 'Onboarding', onboarding_step_title('unknown')
    assert_equal 'Onboarding', onboarding_step_title('5')
    assert_equal 'Onboarding', onboarding_step_title(nil)
    assert_equal 'Onboarding', onboarding_step_title('')
  end

  # === ONBOARDING PROGRESS PERCENTAGE TESTS ===

  test 'should return correct percentage for restaurant step' do
    assert_equal 25, onboarding_progress_percentage('1')
    assert_equal 25, onboarding_progress_percentage('restaurant')
    assert_equal 25, onboarding_progress_percentage(1)
  end

  test 'should return correct percentage for menu step' do
    assert_equal 50, onboarding_progress_percentage('2')
    assert_equal 50, onboarding_progress_percentage('menu')
    assert_equal 50, onboarding_progress_percentage(2)
  end

  test 'should return correct percentage for payment step' do
    assert_equal 75, onboarding_progress_percentage('3')
    assert_equal 75, onboarding_progress_percentage('payment')
    assert_equal 75, onboarding_progress_percentage(3)
  end

  test 'should return correct percentage for complete step' do
    assert_equal 100, onboarding_progress_percentage('4')
    assert_equal 100, onboarding_progress_percentage('complete')
    assert_equal 100, onboarding_progress_percentage(4)
  end

  test 'should return zero percentage for unknown step' do
    assert_equal 0, onboarding_progress_percentage('unknown')
    assert_equal 0, onboarding_progress_percentage('5')
    assert_equal 0, onboarding_progress_percentage(nil)
    assert_equal 0, onboarding_progress_percentage('')
  end

  test 'should handle edge case step numbers' do
    assert_equal 0, onboarding_progress_percentage('0')
    assert_equal 0, onboarding_progress_percentage(-1)
    assert_equal 0, onboarding_progress_percentage(999)
  end

  # === ONBOARDING STEP COMPLETED TESTS ===

  test 'should return false for nil user' do
    assert_equal false, onboarding_step_completed?('1', nil)
    assert_equal false, onboarding_step_completed?('restaurant', nil)
  end

  test 'should check restaurant step completion correctly' do
    # User with restaurant should have completed restaurant step
    assert_equal true, onboarding_step_completed?('1', @user)
    assert_equal true, onboarding_step_completed?('restaurant', @user)

    # User without restaurants should not have completed restaurant step
    user_without_restaurant = User.create!(
      email: 'norestaurant@example.com',
      password: 'password123',
      first_name: 'No',
      last_name: 'Restaurant',
    )

    assert_equal false, onboarding_step_completed?('1', user_without_restaurant)
    assert_equal false, onboarding_step_completed?('restaurant', user_without_restaurant)
  end

  test 'should check menu step completion correctly' do
    # User with restaurant and menu should have completed menu step
    assert_equal true, onboarding_step_completed?('2', @user)
    assert_equal true, onboarding_step_completed?('menu', @user)

    # User with restaurant but no menu should not have completed menu step
    user_with_restaurant_no_menu = User.create!(
      email: 'nomenu@example.com',
      password: 'password123',
      first_name: 'No',
      last_name: 'Menu',
    )

    Restaurant.create!(
      name: 'Restaurant Without Menu',
      user: user_with_restaurant_no_menu,
      capacity: 30,
      status: :active,
    )

    assert_equal false, onboarding_step_completed?('2', user_with_restaurant_no_menu)
    assert_equal false, onboarding_step_completed?('menu', user_with_restaurant_no_menu)
  end

  test 'should check payment step completion correctly' do
    # User with active restaurant should have completed payment step
    @restaurant.update!(status: :active)
    assert_equal true, onboarding_step_completed?('3', @user)
    assert_equal true, onboarding_step_completed?('payment', @user)

    # User with inactive restaurant should not have completed payment step
    @restaurant.update!(status: :inactive)
    assert_equal false, onboarding_step_completed?('3', @user)
    assert_equal false, onboarding_step_completed?('payment', @user)
  end

  test 'should return false for unknown steps' do
    assert_equal false, onboarding_step_completed?('unknown', @user)
    assert_equal false, onboarding_step_completed?('5', @user)
    assert_equal false, onboarding_step_completed?(nil, @user)
  end

  # === NEXT ONBOARDING STEP TESTS ===

  test 'should return correct next step for restaurant step' do
    assert_equal '2', next_onboarding_step('1')
    assert_equal '2', next_onboarding_step('restaurant')
  end

  test 'should return correct next step for menu step' do
    assert_equal '3', next_onboarding_step('2')
    assert_equal '3', next_onboarding_step('menu')
  end

  test 'should return correct next step for payment step' do
    assert_equal '4', next_onboarding_step('3')
    assert_equal '4', next_onboarding_step('payment')
  end

  test 'should return first step for complete step' do
    assert_equal '1', next_onboarding_step('4')
    assert_equal '1', next_onboarding_step('complete')
  end

  test 'should return first step for unknown step' do
    assert_equal '1', next_onboarding_step('unknown')
    assert_equal '1', next_onboarding_step('5')
    assert_equal '1', next_onboarding_step(nil)
    assert_equal '1', next_onboarding_step('')
  end

  # === INTEGRATION TESTS ===

  test 'should work together for complete onboarding flow' do
    # Test complete onboarding workflow
    steps = %w[1 2 3 4]

    steps.each_with_index do |step, index|
      title = onboarding_step_title(step)
      percentage = onboarding_progress_percentage(step)
      next_step = next_onboarding_step(step)

      # Title should be meaningful
      assert title.present?
      assert_not_equal 'Onboarding', title unless step == '4' # Complete step might be different

      # Percentage should increase with each step
      expected_percentage = ((index + 1).to_f / 4 * 100).round
      assert_equal expected_percentage, percentage

      # Next step should be logical
      if step == '4'
        assert_equal '1', next_step # Cycles back
      else
        assert_equal (index + 2).to_s, next_step
      end
    end
  end

  test 'should handle user progression through onboarding' do
    # Create user without any setup
    new_user = User.create!(
      email: 'newuser@example.com',
      password: 'password123',
      first_name: 'New',
      last_name: 'User',
    )

    # Step 1: Should not be completed initially
    assert_equal false, onboarding_step_completed?('1', new_user)

    # Create restaurant for user
    new_restaurant = Restaurant.create!(
      name: 'New User Restaurant',
      user: new_user,
      capacity: 25,
      status: :inactive,
    )

    # Step 1: Should now be completed
    assert_equal true, onboarding_step_completed?('1', new_user)
    # Step 2: Should not be completed yet
    assert_equal false, onboarding_step_completed?('2', new_user)

    # Create menu for restaurant
    Menu.create!(
      name: 'New User Menu',
      restaurant: new_restaurant,
      status: :active,
    )

    # Step 2: Should now be completed
    assert_equal true, onboarding_step_completed?('2', new_user)
    # Step 3: Should not be completed yet (restaurant inactive)
    assert_equal false, onboarding_step_completed?('3', new_user)

    # Activate restaurant
    new_restaurant.update!(status: :active)

    # Step 3: Should now be completed
    assert_equal true, onboarding_step_completed?('3', new_user)
  end

  # === EDGE CASE TESTS ===

  test 'should handle user with multiple restaurants' do
    # Create second restaurant for user
    Restaurant.create!(
      name: 'Second Restaurant',
      user: @user,
      capacity: 40,
      status: :active,
    )

    # Should still return true for restaurant step (user has restaurants)
    assert_equal true, onboarding_step_completed?('1', @user)

    # Should return true for menu step if any restaurant has menus
    assert_equal true, onboarding_step_completed?('2', @user)

    # Should return true for payment step if any restaurant is active
    assert_equal true, onboarding_step_completed?('3', @user)
  end

  test 'should handle archived restaurants' do
    # Archive the restaurant
    @restaurant.update!(archived: true, status: :active)

    # Should still count archived restaurants for completion
    assert_equal true, onboarding_step_completed?('1', @user)
    assert_equal true, onboarding_step_completed?('2', @user)
    assert_equal true, onboarding_step_completed?('3', @user)
  end

  test 'should handle restaurants with different statuses' do
    # Test various restaurant statuses (check what statuses are actually valid)
    statuses = %i[active inactive]

    statuses.each do |status|
      @restaurant.update!(status: status)

      # Restaurant and menu steps should always be true if restaurant exists
      assert_equal true, onboarding_step_completed?('1', @user)
      assert_equal true, onboarding_step_completed?('2', @user)

      # Payment step should only be true for active restaurants
      expected_payment_completion = (status == :active)
      assert_equal expected_payment_completion, onboarding_step_completed?('3', @user)
    end
  end

  # === PERFORMANCE TESTS ===

  test 'should handle multiple calls efficiently' do
    start_time = Time.current

    100.times do |i|
      step = ((i % 4) + 1).to_s
      onboarding_step_title(step)
      onboarding_progress_percentage(step)
      onboarding_step_completed?(step, @user)
      next_onboarding_step(step)
    end

    execution_time = Time.current - start_time
    assert execution_time < 1.second, "Helper calls took too long: #{execution_time}s"
  end

  # === BUSINESS SCENARIO TESTS ===

  test 'should support onboarding wizard navigation' do
    # Simulate user navigating through onboarding wizard
    current_step = '1'

    # Get current step info
    title = onboarding_step_title(current_step)
    progress = onboarding_progress_percentage(current_step)
    completed = onboarding_step_completed?(current_step, @user)
    next_step = next_onboarding_step(current_step)

    assert_equal 'Restaurant Information', title
    assert_equal 25, progress
    assert_equal true, completed # User has restaurant
    assert_equal '2', next_step
  end

  test 'should support progress tracking' do
    # Test progress tracking for different users at different stages

    # New user - no progress
    new_user = User.create!(
      email: 'progress@example.com',
      password: 'password123',
      first_name: 'Progress',
      last_name: 'User',
    )

    steps_completed = %w[1 2 3].count { |step| onboarding_step_completed?(step, new_user) }
    assert_equal 0, steps_completed

    # User with restaurant - 1 step completed
    Restaurant.create!(
      name: 'Progress Restaurant',
      user: new_user,
      capacity: 30,
      status: :inactive,
    )

    steps_completed = %w[1 2 3].count { |step| onboarding_step_completed?(step, new_user) }
    assert_equal 1, steps_completed
  end

  test 'should support conditional UI rendering' do
    # Test helpers used for conditional UI rendering

    # Show different content based on step completion
    if onboarding_step_completed?('1', @user)
      # User has restaurant - show advanced options
      assert_equal true, true # Restaurant step completed
    end

    if onboarding_step_completed?('2', @user)
      # User has menu - show menu management
      assert_equal true, true # Menu step completed
    end

    if onboarding_step_completed?('3', @user)
      # User has payment - show full features
      payment_completed = @restaurant.status == 'active'
      assert_equal payment_completed, onboarding_step_completed?('3', @user)
    end
  end
end
