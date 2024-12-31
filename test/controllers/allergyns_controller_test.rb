require "test_helper"

class AllergynsControllerTest < ActionView::TestCase

  def current_user
    @current_user
  end

  setup do
    @current_user = users(:one)
    @allergyn = allergyns(:one)
  end

  test "should get index" do
    get allergyns_url
    assert_response :success
  end

  test "should get new" do
    get new_allergyn_url
    assert_response :success
  end

  test "should create allergyn" do
    assert_difference("Allergyn.count") do
      post allergyns_url, params: { allergyn: { description: @allergyn.description, menuitem_id: @allergyn.menuitem_id, name: @allergyn.name, symbol: @allergyn.symbol } }
    end

    assert_redirected_to allergyn_url(Allergyn.last)
  end

  test "should show allergyn" do
    get allergyn_url(@allergyn)
    assert_response :success
  end

  test "should get edit" do
    get edit_allergyn_url(@allergyn)
    assert_response :success
  end

  test "should update allergyn" do
    patch allergyn_url(@allergyn), params: { allergyn: { description: @allergyn.description, menuitem_id: @allergyn.menuitem_id, name: @allergyn.name, symbol: @allergyn.symbol } }
    assert_redirected_to allergyn_url(@allergyn)
  end

  test "should destroy allergyn" do
    assert_difference("Allergyn.count", 0) do
      delete allergyn_url(@allergyn)
    end

    assert_redirected_to allergyns_url
  end
end
