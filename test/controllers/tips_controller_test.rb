require "test_helper"

class TipsControllerTest < ActionView::TestCase

  def current_user
    @current_user
  end

  setup do
    @current_user = users(:one)
    @tip = tips(:one)
  end

  test "should get index" do
    get tips_url
    assert_response :success
  end

  test "should get new" do
    get new_tip_url
    assert_response :success
  end

  test "should create tip" do
    assert_difference("Tip.count") do
      post tips_url, params: { tip: { percentage: @tip.percentage, restaurant_id: @tip.restaurant_id } }
    end

    assert_redirected_to tip_url(Tip.last)
  end

  test "should show tip" do
    get tip_url(@tip)
    assert_response :success
  end

  test "should get edit" do
    get edit_tip_url(@tip)
    assert_response :success
  end

  test "should update tip" do
    patch tip_url(@tip), params: { tip: { percentage: @tip.percentage, restaurant_id: @tip.restaurant_id } }
    assert_redirected_to tip_url(@tip)
  end

  test "should destroy tip" do
    assert_difference("Tip.count", 0) do
      delete tip_url(@tip)
    end

    assert_redirected_to tips_url
  end
end
