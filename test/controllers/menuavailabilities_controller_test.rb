require "test_helper"

class MenuavailabilitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @menuavailability = menuavailabilities(:one)
  end

  test "should get index" do
    get menuavailabilities_url
    assert_response :success
  end

  test "should get new" do
    get new_menuavailability_url
    assert_response :success
  end

  test "should create menuavailability" do
    assert_difference("Menuavailability.count") do
      post menuavailabilities_url, params: { menuavailability: { dayofweek: @menuavailability.dayofweek, endhour: @menuavailability.endhour, endmin: @menuavailability.endmin, menu_id: @menuavailability.menu_id, starthour: @menuavailability.starthour, startmin: @menuavailability.startmin } }
    end

    assert_redirected_to menuavailability_url(Menuavailability.last)
  end

  test "should show menuavailability" do
    get menuavailability_url(@menuavailability)
    assert_response :success
  end

  test "should get edit" do
    get edit_menuavailability_url(@menuavailability)
    assert_response :success
  end

  test "should update menuavailability" do
    patch menuavailability_url(@menuavailability), params: { menuavailability: { dayofweek: @menuavailability.dayofweek, endhour: @menuavailability.endhour, endmin: @menuavailability.endmin, menu_id: @menuavailability.menu_id, starthour: @menuavailability.starthour, startmin: @menuavailability.startmin } }
    assert_redirected_to menuavailability_url(@menuavailability)
  end

  test "should destroy menuavailability" do
    assert_difference("Menuavailability.count", -1) do
      delete menuavailability_url(@menuavailability)
    end

    assert_redirected_to menuavailabilities_url
  end
end
