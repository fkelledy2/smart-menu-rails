require 'test_helper'

class TaxesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @tax = taxes(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get taxes_url
    assert_response :success
  end

  test 'should get new' do
    get new_tax_url, params: { restaurant_id: @restaurant.id }
    assert_response :success
  end

  #   test "should create tax" do
  #     assert_difference("Tax.count") do
  #       post taxes_url, params: { tax: { name: @tax.name, restaurant_id: @tax.restaurant_id, taxpercentage: @tax.taxpercentage, taxtype: @tax.taxtype } }
  #     end
  #     assert_redirected_to edit_restaurant_url(@tax.restaurant)
  #   end

  test 'should show tax' do
    get tax_url(@tax)
    assert_response :success
  end

  test 'should get edit' do
    get edit_tax_url(@tax)
    assert_response :success
  end

  test 'should update tax' do
    patch tax_url(@tax),
          params: { tax: { name: @tax.name, restaurant_id: @tax.restaurant_id, taxpercentage: @tax.taxpercentage,
                           taxtype: @tax.taxtype, } }
    #     assert_redirected_to edit_restaurant_url(@tax.restaurant)
  end

  test 'should destroy tax' do
    assert_difference('Tax.count', 0) do
      delete tax_url(@tax)
    end
    #     assert_redirected_to edit_restaurant_url(@tax.restaurant)
  end
end
