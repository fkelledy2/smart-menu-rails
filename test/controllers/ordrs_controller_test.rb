require 'test_helper'

class OrdrsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_ordrs_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_ordr_url(@restaurant)
    assert_response :success
  end

  #   test "should create ordr" do
  #     assert_difference("Ordr.count") do
  #       post ordrs_url, params: { ordr: { deliveredAt: @ordr.deliveredAt, employee_id: @ordr.employee_id, gross: @ordr.gross, menu_id: @ordr.menu_id, nett: @ordr.nett, orderedAt: @ordr.orderedAt, paidAt: @ordr.paidAt, restaurant_id: @ordr.restaurant_id, service: @ordr.service, tablesetting_id: @ordr.tablesetting_id, tax: @ordr.tax, tip: @ordr.tip } }
  #     end
  #     assert_redirected_to ordr_url(@ordr)
  #   end

  test 'should show ordr' do
    get restaurant_ordr_url(@restaurant, @ordr)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_ordr_url(@restaurant, @ordr)
    assert_response :success
  end

  test 'should update ordr' do
    patch restaurant_ordr_url(@restaurant, @ordr),
          params: { ordr: { deliveredAt: @ordr.deliveredAt, employee_id: @ordr.employee_id, gross: @ordr.gross,
                            menu_id: @ordr.menu_id, nett: @ordr.nett, orderedAt: @ordr.orderedAt, paidAt: @ordr.paidAt, restaurant_id: @ordr.restaurant_id, service: @ordr.service, tablesetting_id: @ordr.tablesetting_id, tax: @ordr.tax, tip: @ordr.tip, } }
    assert_response :success
  end

  #   test "should destroy ordr" do
  #     assert_difference("Ordr.count", 0) do
  #       delete ordr_url(@ordr)
  #     end
  #     assert_redirected_to ordrs_url
  #   end
end
