require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create a simple plan without complex associations
    @plan = Plan.create!(
      key: 'test_free',
      descriptionKey: 'Test Free Plan',
      status: 1,
      pricePerMonth: 0,
      action: 0,
      locations: 1,
      menusperlocation: 1,
      itemspermenu: 10,
      languages: 1
    )
    
    # Create user with minimal data
    @user = User.create!(
      email: 'test@example.com',
      password: 'password123',
      first_name: 'Test',
      last_name: 'User',
      plan: @plan
    )
    
    sign_in @user
  end

  test "should get onboarding step 1" do
    get onboarding_path
    assert_response :success
    assert_match /Welcome to Smart Menu/, response.body
  end

  test "should redirect completed users to root" do
    @user.onboarding_session.update!(status: :completed)
    get onboarding_path
    assert_redirected_to root_path
  end

  test "should update account details" do
    patch onboarding_path, params: {
      user: { name: "Updated Name" },
      step: 1
    }
    assert_redirected_to onboarding_step_path(2)
    assert_equal "Updated Name", @user.reload.name
  end

  test "should update restaurant details" do
    patch onboarding_path, params: {
      onboarding_session: {
        restaurant_name: "Test Restaurant",
        restaurant_type: "casual_dining",
        cuisine_type: "italian",
        location: "New York, NY",
        phone: "555-1234"
      },
      step: 2
    }
    assert_redirected_to onboarding_step_path(3)
    
    onboarding = @user.onboarding_session.reload
    assert_equal "Test Restaurant", onboarding.restaurant_name
    assert_equal "casual_dining", onboarding.restaurant_type
  end

  test "should handle plan selection" do
    patch onboarding_path, params: {
      plan_id: @plan.id,
      step: 3
    }
    assert_redirected_to onboarding_step_path(4)
    assert_equal @plan, @user.reload.plan
  end

  test "should return completion status as json" do
    @user.onboarding_session.update!(status: :completed)
    get onboarding_path, as: :json
    
    json_response = JSON.parse(response.body)
    assert json_response["completed"]
    assert_not_nil json_response["dashboard_url"]
  end
end
