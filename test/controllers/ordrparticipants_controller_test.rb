require 'test_helper'

class OrdrparticipantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @ordrparticipant = ordrparticipants(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_ordrparticipants_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_ordrparticipant_url(@restaurant)
    assert_response :success
  end

  #   test "should create ordrparticipant" do
  #     assert_difference("Ordrparticipant.count") do
  #       post ordrparticipants_url, params: { ordrparticipant: { employee_id: @ordrparticipant.employee_id, ordr_id: @ordrparticipant.ordr_id, ordritem_id: @ordrparticipant.ordritem_id, role: @ordrparticipant.role, sessionid: @ordrparticipant.sessionid } }
  #     end
  #     assert_redirected_to smartmenu_path(@ordrparticipant.ordr.menu.slug)
  #   end

  test 'should show ordrparticipant' do
    get restaurant_ordrparticipant_url(@restaurant, @ordrparticipant)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_ordrparticipant_url(@restaurant, @ordrparticipant)
    assert_response :success
  end

  test 'should update ordrparticipant' do
    patch restaurant_ordrparticipant_url(@restaurant, @ordrparticipant),
          params: { ordrparticipant: { employee_id: @ordrparticipant.employee_id, ordr_id: @ordrparticipant.ordr_id,
                                       ordritem_id: @ordrparticipant.ordritem_id, role: @ordrparticipant.role, sessionid: @ordrparticipant.sessionid, } }
    assert_response :success
  end

  test 'should destroy ordrparticipant' do
    assert_difference('Ordrparticipant.count', 0) do
      delete restaurant_ordrparticipant_url(@restaurant, @ordrparticipant)
    end
    assert_response :success
  end
end
