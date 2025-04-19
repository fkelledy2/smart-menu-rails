require "test_helper"

class MenulocalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @menulocale = menulocales(:one)
  end

  test "should get index" do
    get menulocales_url
    assert_response :success
  end

  test "should get new" do
    get new_menulocale_url
    assert_response :success
  end

  test "should create menulocale" do
    assert_difference("Menulocale.count") do
      post menulocales_url, params: { menulocale: { description: @menulocale.description, locale: @menulocale.locale, menu_id: @menulocale.menu_id, name: @menulocale.name, status: @menulocale.status } }
    end

    assert_redirected_to menulocale_url(Menulocale.last)
  end

  test "should show menulocale" do
    get menulocale_url(@menulocale)
    assert_response :success
  end

  test "should get edit" do
    get edit_menulocale_url(@menulocale)
    assert_response :success
  end

  test "should update menulocale" do
    patch menulocale_url(@menulocale), params: { menulocale: { description: @menulocale.description, locale: @menulocale.locale, menu_id: @menulocale.menu_id, name: @menulocale.name, status: @menulocale.status } }
    assert_redirected_to menulocale_url(@menulocale)
  end

  test "should destroy menulocale" do
    assert_difference("Menulocale.count", -1) do
      delete menulocale_url(@menulocale)
    end

    assert_redirected_to menulocales_url
  end
end
