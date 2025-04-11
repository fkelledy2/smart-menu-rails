require "test_helper"

class MenuitemlocalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @menuitemlocale = menuitemlocales(:one)
  end

  test "should get index" do
    get menuitemlocales_url
    assert_response :success
  end

  test "should get new" do
    get new_menuitemlocale_url
    assert_response :success
  end

  test "should create menuitemlocale" do
    assert_difference("Menuitemlocale.count") do
      post menuitemlocales_url, params: { menuitemlocale: { description: @menuitemlocale.description, locale: @menuitemlocale.locale, menuitem_id: @menuitemlocale.menuitem_id, name: @menuitemlocale.name, status: @menuitemlocale.status } }
    end

    assert_redirected_to menuitemlocale_url(Menuitemlocale.last)
  end

  test "should show menuitemlocale" do
    get menuitemlocale_url(@menuitemlocale)
    assert_response :success
  end

  test "should get edit" do
    get edit_menuitemlocale_url(@menuitemlocale)
    assert_response :success
  end

  test "should update menuitemlocale" do
    patch menuitemlocale_url(@menuitemlocale), params: { menuitemlocale: { description: @menuitemlocale.description, locale: @menuitemlocale.locale, menuitem_id: @menuitemlocale.menuitem_id, name: @menuitemlocale.name, status: @menuitemlocale.status } }
    assert_redirected_to menuitemlocale_url(@menuitemlocale)
  end

  test "should destroy menuitemlocale" do
    assert_difference("Menuitemlocale.count", -1) do
      delete menuitemlocale_url(@menuitemlocale)
    end

    assert_redirected_to menuitemlocales_url
  end
end
