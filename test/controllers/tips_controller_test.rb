require 'test_helper'

class TipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @tip = tips(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get index' do
    get restaurant_tips_url(@restaurant)
    assert_response :success
  end

  test 'should get new' do
    get new_restaurant_tip_url(@restaurant)
    assert_response :success
  end

  #   test "should create tip" do
  #     assert_difference("Tip.count") do
  #       post tips_url, params: { tip: { percentage: @tip.percentage, restaurant_id: @tip.restaurant_id } }
  #     end
  #     assert_redirected_to edit_restaurant_url(@tip.restaurant)
  #   end

  test 'should show tip' do
    get restaurant_tip_url(@restaurant, @tip)
    assert_response :success
  end

  test 'should get edit' do
    get edit_restaurant_tip_url(@restaurant, @tip)
    assert_response :success
  end

  test 'should update tip' do
    patch restaurant_tip_url(@restaurant, @tip),
          params: { tip: { percentage: @tip.percentage, restaurant_id: @tip.restaurant_id } }
    assert_response :success
  end

  test 'should destroy tip' do
    assert_difference('Tip.count', 0) do
      delete restaurant_tip_url(@restaurant, @tip)
    end
    assert_response :success
  end
end
