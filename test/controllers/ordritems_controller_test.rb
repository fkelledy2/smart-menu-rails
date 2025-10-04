require 'test_helper'

class OrdritemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @ordritem = ordritems(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_ordritems_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_ordritem_url(@restaurant)
    assert_response :success
  end

  #   test "should create ordritem" do
  #     assert_difference("Ordritem.count") do
  #       post ordritems_url, params: { ordritem: { menuitem_id: @ordritem.menuitem_id, ordr_id: @ordritem.ordr_id } }
  #     end
  #     assert_redirected_to restaurant_ordrs_path(@ordritem.ordr.restaurant)
  #   end

  test 'should show ordritem' do
    get restaurant_ordritem_url(@restaurant, @ordritem)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_ordritem_url(@restaurant, @ordritem)
    assert_response :success
  end

  test 'should update ordritem' do
    patch restaurant_ordritem_url(@restaurant, @ordritem),
          params: { ordritem: { menuitem_id: @ordritem.menuitem_id, ordr_id: @ordritem.ordr_id } }
    assert_response :success
  end

  #   test "should destroy ordritem" do
  #     assert_difference("Ordritem.count", 0) do
  #       delete ordritem_url(@ordritem)
  #     end
  #     assert_redirected_to edit_restaurant_url(@ordritem.ordr.menu.restaurant)
  #   end
end
