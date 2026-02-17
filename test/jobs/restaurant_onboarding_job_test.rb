require 'test_helper'

class RestaurantOnboardingJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  # NOTE: This job is legacy — the OnboardingController now creates
  # restaurants directly and calls RestaurantProvisioningService.
  # The job is kept for backward compatibility with any queued jobs.

  setup do
    @user = users(:one)
    @plan = plans(:one)

    # Create onboarding session with simplified data (only restaurant_name)
    @onboarding = OnboardingSession.create!(
      user: @user,
      status: :started,
    )
    @onboarding.restaurant_name = 'Test Restaurant'
    @onboarding.save!
  end

  # === BASIC JOB EXECUTION TESTS ===

  test 'should be configured with correct queue' do
    job = RestaurantOnboardingJob.new
    assert_equal 'default', job.queue_name
  end

  test 'should perform job successfully with valid data' do
    initial_restaurant_count = Restaurant.count
    initial_menu_count = Menu.count

    assert_nothing_raised do
      RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)
    end

    assert_equal initial_restaurant_count + 1, Restaurant.count
    assert_equal initial_menu_count + 1, Menu.count
  end

  test 'should update onboarding session status to completed' do
    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)

    @onboarding.reload
    assert_equal 'completed', @onboarding.status
    assert_not_nil @onboarding.restaurant
    assert_not_nil @onboarding.menu
  end

  test 'should handle missing user gracefully' do
    assert_nothing_raised do
      RestaurantOnboardingJob.perform_now(99999, @onboarding.id)
    end

    @onboarding.reload
    assert_not_equal 'completed', @onboarding.status
  end

  test 'should handle missing onboarding session gracefully' do
    initial_restaurant_count = Restaurant.count

    assert_nothing_raised do
      RestaurantOnboardingJob.perform_now(@user.id, 99999)
    end

    assert_equal initial_restaurant_count, Restaurant.count
  end

  # === RESTAURANT CREATION TESTS ===

  test 'should create restaurant with correct attributes' do
    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)

    restaurant = Restaurant.last
    assert_equal 'Test Restaurant', restaurant.name
    assert_equal @user, restaurant.user
    assert_equal 'USD', restaurant.currency
    assert_equal 50, restaurant.capacity
    assert restaurant.allowOrdering
    assert_equal 'active', restaurant.status
    assert_not restaurant.archived
  end

  test 'should create default restaurant settings' do
    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)

    restaurant = Restaurant.last

    assert restaurant.tablesettings.exists?
    assert restaurant.taxes.exists?
    assert restaurant.tips.exists?
    assert restaurant.restaurantlocales.exists?
    assert_equal 2, restaurant.restaurantlocales.count
    assert restaurant.restaurantavailabilities.exists?
    assert_equal 6, restaurant.restaurantavailabilities.count
    assert restaurant.allergyns.exists?
    assert_equal 2, restaurant.allergyns.count
    assert restaurant.sizes.exists?
    assert_equal 3, restaurant.sizes.count
  end

  test 'should create owner employee record' do
    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)

    restaurant = Restaurant.last
    assert restaurant.employees.exists?

    owner_employee = restaurant.employees.first
    assert_equal @user, owner_employee.user
    assert_equal 'manager', owner_employee.role
    assert_equal 'active', owner_employee.status
  end

  # === MENU CREATION TESTS ===

  test 'should create menu with Demo Menu name' do
    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)

    menu = Menu.last
    assert_equal 'Demo Menu', menu.name
    assert_equal 'active', menu.status
    assert_not menu.archived
    assert menu.allowOrdering
  end

  test 'should create menu availabilities matching restaurant hours' do
    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)

    restaurant = Restaurant.last
    menu = Menu.last

    assert_equal restaurant.restaurantavailabilities.count, menu.menuavailabilities.count
  end

  # === ANALYTICS TRACKING TESTS ===

  test 'should track analytics events' do
    analytics_calls = []

    AnalyticsService.stub :track_onboarding_completed, ->(user, data) { analytics_calls << [:onboarding_completed, user, data] } do
      AnalyticsService.stub :track_restaurant_created, ->(user, restaurant) { analytics_calls << [:restaurant_created, user, restaurant] } do
        AnalyticsService.stub :track_menu_created, ->(user, menu) { analytics_calls << [:menu_created, user, menu] } do
          AnalyticsService.stub :identify_user, ->(user, traits) { analytics_calls << [:identify_user, user, traits] } do
            RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)
          end
        end
      end
    end

    assert_equal 4, analytics_calls.length

    onboarding_call = analytics_calls.find { |call| call[0] == :onboarding_completed }
    assert_not_nil onboarding_call
    assert_equal @user, onboarding_call[1]

    identify_call = analytics_calls.find { |call| call[0] == :identify_user }
    assert_not_nil identify_call
    traits = identify_call[2]
    assert traits[:has_restaurant]
    assert traits[:has_menu]
    assert traits[:onboarding_completed]
  end

  test 'should handle analytics failures gracefully' do
    AnalyticsService.stub :track_onboarding_completed, ->(*) { raise StandardError, 'Analytics error' } do
      assert_nothing_raised do
        RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)
      end
    end

    @onboarding.reload
    assert_equal 'completed', @onboarding.status
  end

  # === SMART MENU SYNC TESTS ===

  test 'should call SmartMenuGeneratorJob perform_async' do
    sync_job_called = false
    SmartMenuGeneratorJob.stub :perform_async, ->(restaurant_id) { sync_job_called = true } do
      RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)
    end

    assert sync_job_called, 'SmartMenuGeneratorJob.perform_async should have been called'
  end

  # === ERROR HANDLING TESTS ===

  test 'should handle database transaction rollback for blank name' do
    initial_restaurant_count = Restaurant.count

    blank_onboarding = OnboardingSession.create!(user: @user, status: :started)
    blank_onboarding.restaurant_name = ''
    blank_onboarding.save!

    assert_raises ActiveRecord::RecordInvalid do
      RestaurantOnboardingJob.perform_now(@user.id, blank_onboarding.id)
    end

    assert_equal initial_restaurant_count, Restaurant.count
  end

  test 'should log errors for missing user' do
    log_output = StringIO.new
    original_logger = Rails.logger
    Rails.logger = Logger.new(log_output)

    begin
      RestaurantOnboardingJob.perform_now(99999, @onboarding.id)
      log_content = log_output.string
      assert_includes log_content, 'User with ID 99999 not found'
    ensure
      Rails.logger = original_logger
    end
  end

  # === INTEGRATION TESTS ===

  test 'should work with real database operations' do
    initial_counts = {
      restaurants: Restaurant.count,
      menus: Menu.count,
      employees: Employee.count,
      tablesettings: Tablesetting.count,
      taxes: Tax.count,
      tips: Tip.count,
      allergyns: Allergyn.count,
      sizes: Size.count,
    }

    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)

    assert_equal initial_counts[:restaurants] + 1, Restaurant.count
    assert_equal initial_counts[:menus] + 1, Menu.count
    assert_equal initial_counts[:employees] + 1, Employee.count
    assert_equal initial_counts[:tablesettings] + 1, Tablesetting.count
    assert_equal initial_counts[:taxes] + 1, Tax.count
    assert_equal initial_counts[:tips] + 1, Tip.count
    assert_equal initial_counts[:allergyns] + 2, Allergyn.count
    assert_equal initial_counts[:sizes] + 3, Size.count
  end

  test 'should complete job execution within reasonable time' do
    start_time = Time.current
    RestaurantOnboardingJob.perform_now(@user.id, @onboarding.id)
    execution_time = Time.current - start_time
    assert execution_time < 10.seconds, "Job took too long: #{execution_time}s"
  end
end
