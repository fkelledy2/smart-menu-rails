require "test_helper"

class OrdractionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ordraction = ordractions(:one)
  end

  test "should get index" do
    get ordractions_url
    assert_response :success
  end

  test "should get new" do
    get new_ordraction_url
    assert_response :success
  end

  test "should create ordraction" do
    assert_difference("Ordraction.count") do
      post ordractions_url, params: { ordraction: { action: @ordraction.action, employee_id: @ordraction.employee_id, ordr_id: @ordraction.ordr_id, ordritem_id: @ordraction.ordritem_id, ordrparticipant_id: @ordraction.ordrparticipant_id, sessionid: @ordraction.sessionid } }
    end

    assert_redirected_to ordraction_url(Ordraction.last)
  end

  test "should show ordraction" do
    get ordraction_url(@ordraction)
    assert_response :success
  end

  test "should get edit" do
    get edit_ordraction_url(@ordraction)
    assert_response :success
  end

  test "should update ordraction" do
    patch ordraction_url(@ordraction), params: { ordraction: { action: @ordraction.action, employee_id: @ordraction.employee_id, ordr_id: @ordraction.ordr_id, ordritem_id: @ordraction.ordritem_id, ordrparticipant_id: @ordraction.ordrparticipant_id, sessionid: @ordraction.sessionid } }
    assert_redirected_to ordraction_url(@ordraction)
  end

  test "should destroy ordraction" do
    assert_difference("Ordraction.count", -1) do
      delete ordraction_url(@ordraction)
    end

    assert_redirected_to ordractions_url
  end
end
