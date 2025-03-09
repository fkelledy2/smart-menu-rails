require "test_helper"

class OrdrparticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @ordrparticipant = ordrparticipants(:one)
  end

  test "should get index" do
    get ordrparticipants_url
    assert_response :success
  end

  test "should get new" do
    get new_ordrparticipant_url
    assert_response :success
  end

#   test "should create ordrparticipant" do
#     assert_difference("Ordrparticipant.count") do
#       post ordrparticipants_url, params: { ordrparticipant: { employee_id: @ordrparticipant.employee_id, ordr_id: @ordrparticipant.ordr_id, ordritem_id: @ordrparticipant.ordritem_id, role: @ordrparticipant.role, sessionid: @ordrparticipant.sessionid } }
#     end
#     assert_redirected_to smartmenu_path(@ordrparticipant.ordr.menu.slug)
#   end

  test "should show ordrparticipant" do
    get ordrparticipant_url(@ordrparticipant)
    assert_response :success
  end

  test "should get edit" do
    get edit_ordrparticipant_url(@ordrparticipant)
    assert_response :success
  end

  test "should update ordrparticipant" do
    patch ordrparticipant_url(@ordrparticipant), params: { ordrparticipant: { employee_id: @ordrparticipant.employee_id, ordr_id: @ordrparticipant.ordr_id, ordritem_id: @ordrparticipant.ordritem_id, role: @ordrparticipant.role, sessionid: @ordrparticipant.sessionid } }
#     assert_redirected_to smartmenu_path(@ordrparticipant.ordr.menu.slug)
  end

  test "should destroy ordrparticipant" do
    assert_difference("Ordrparticipant.count", 0) do
      delete ordrparticipant_url(@ordrparticipant)
    end
#     assert_redirected_to ordrparticipants_url
  end
end
