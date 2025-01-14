require "test_helper"

class SmartmenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @smartmenu = smartmenus(:one)
  end

  test "should get index" do
    get smartmenus_url
    assert_response :success
  end

  test "should get new" do
    get new_smartmenu_url
    assert_response :success
  end

  test "should create smartmenu" do
    assert_difference("Smartmenu.count") do
      post smartmenus_url, params: { smartmenu: { menu_id: @smartmenu.menu_id, restaurant_id: @smartmenu.restaurant_id, slug: @smartmenu.slug, tablesetting_id: @smartmenu.tablesetting_id } }
    end

    assert_redirected_to smartmenu_url(Smartmenu.last)
  end

  test "should show smartmenu" do
    get smartmenu_url(@smartmenu)
    assert_response :success
  end

  test "should get edit" do
    get edit_smartmenu_url(@smartmenu)
    assert_response :success
  end

  test "should update smartmenu" do
    patch smartmenu_url(@smartmenu), params: { smartmenu: { menu_id: @smartmenu.menu_id, restaurant_id: @smartmenu.restaurant_id, slug: @smartmenu.slug, tablesetting_id: @smartmenu.tablesetting_id } }
    assert_redirected_to smartmenu_url(@smartmenu)
  end

  test "should destroy smartmenu" do
    assert_difference("Smartmenu.count", -1) do
      delete smartmenu_url(@smartmenu)
    end

    assert_redirected_to smartmenus_url
  end
end
