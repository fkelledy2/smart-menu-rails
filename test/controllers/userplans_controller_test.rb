require "test_helper"

class UserplansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @userplan = userplans(:one)
  end

  test "should get index" do
    get userplans_url
    assert_response :success
  end

  test "should get new" do
    get new_userplan_url
    assert_response :success
  end

  test "should create userplan" do
    assert_difference("Userplan.count") do
      post userplans_url, params: { userplan: { plan_id: @userplan.plan_id, user_id: @userplan.user_id } }
    end

    assert_redirected_to userplan_url(Userplan.last)
  end

  test "should show userplan" do
    get userplan_url(@userplan)
    assert_response :success
  end

  test "should get edit" do
    get edit_userplan_url(@userplan)
    assert_response :success
  end

  test "should update userplan" do
    patch userplan_url(@userplan), params: { userplan: { plan_id: @userplan.plan_id, user_id: @userplan.user_id } }
    assert_redirected_to userplan_url(@userplan)
  end

  test "should destroy userplan" do
    assert_difference("Userplan.count", -1) do
      delete userplan_url(@userplan)
    end

    assert_redirected_to userplans_url
  end
end
