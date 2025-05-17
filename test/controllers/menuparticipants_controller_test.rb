require "test_helper"

class MenuparticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @menuparticipant = menuparticipants(:one)
  end

  test "should get index" do
    get menuparticipants_url
    assert_response :success
  end

  test "should get new" do
    get new_menuparticipant_url
    assert_response :success
  end

  test "should create menuparticipant" do
    assert_difference("Menuparticipant.count") do
      post menuparticipants_url, params: { menuparticipant: { preferredlocale: @menuparticipant.preferredlocale, sessionid: @menuparticipant.sessionid, smartmenu_id: @menuparticipant.smartmenu_id } }
    end

    assert_redirected_to menuparticipant_url(Menuparticipant.last)
  end

  test "should show menuparticipant" do
    get menuparticipant_url(@menuparticipant)
    assert_response :success
  end

  test "should get edit" do
    get edit_menuparticipant_url(@menuparticipant)
    assert_response :success
  end

  test "should update menuparticipant" do
    patch menuparticipant_url(@menuparticipant), params: { menuparticipant: { preferredlocale: @menuparticipant.preferredlocale, sessionid: @menuparticipant.sessionid, smartmenu_id: @menuparticipant.smartmenu_id } }
    assert_redirected_to menuparticipant_url(@menuparticipant)
  end

  test "should destroy menuparticipant" do
    assert_difference("Menuparticipant.count", -1) do
      delete menuparticipant_url(@menuparticipant)
    end

    assert_redirected_to menuparticipants_url
  end
end
