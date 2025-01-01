require "test_helper"

class OrdritemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @ordritem = ordritems(:one)
  end

  test "should get index" do
    get ordritems_url
    assert_response :success
  end

  test "should get new" do
    get new_ordritem_url
    assert_response :success
  end

  test "should create ordritem" do
    assert_difference("Ordritem.count") do
      post ordritems_url, params: { ordritem: { ordrparticipant_id: @ordritem.ordrparticipant_id, menuitem_id: @ordritem.menuitem_id, ordr_id: @ordritem.ordr_id } }
    end
    assert_redirected_to restaurant_ordrs_path(@ordritem.ordr.restaurant)
  end

  test "should show ordritem" do
    get ordritem_url(@ordritem)
    assert_response :success
  end

  test "should get edit" do
    get edit_ordritem_url(@ordritem)
    assert_response :success
  end

  test "should update ordritem" do
    patch ordritem_url(@ordritem), params: { ordritem: { menuitem_id: @ordritem.menuitem_id, ordr_id: @ordritem.ordr_id } }
    assert_redirected_to restaurant_ordrs_path(@ordritem.ordr.restaurant)
  end

#   test "should destroy ordritem" do
#     assert_difference("Ordritem.count", 0) do
#       delete ordritem_url(@ordritem)
#     end
#     assert_redirected_to edit_restaurant_url(@ordritem.ordr.menu.restaurant)
#   end
end
