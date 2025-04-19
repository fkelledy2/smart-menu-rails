require "test_helper"

class MenusectionlocalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @menusectionlocale = menusectionlocales(:one)
  end

  test "should get index" do
    get menusectionlocales_url
    assert_response :success
  end

  test "should get new" do
    get new_menusectionlocale_url
    assert_response :success
  end

  test "should create menusectionlocale" do
    assert_difference("Menusectionlocale.count") do
      post menusectionlocales_url, params: { menusectionlocale: { description: @menusectionlocale.description, locale: @menusectionlocale.locale, menusection_id: @menusectionlocale.menusection_id, name: @menusectionlocale.name, status: @menusectionlocale.status } }
    end

    assert_redirected_to menusectionlocale_url(Menusectionlocale.last)
  end

  test "should show menusectionlocale" do
    get menusectionlocale_url(@menusectionlocale)
    assert_response :success
  end

  test "should get edit" do
    get edit_menusectionlocale_url(@menusectionlocale)
    assert_response :success
  end

  test "should update menusectionlocale" do
    patch menusectionlocale_url(@menusectionlocale), params: { menusectionlocale: { description: @menusectionlocale.description, locale: @menusectionlocale.locale, menusection_id: @menusectionlocale.menusection_id, name: @menusectionlocale.name, status: @menusectionlocale.status } }
    assert_redirected_to menusectionlocale_url(@menusectionlocale)
  end

  test "should destroy menusectionlocale" do
    assert_difference("Menusectionlocale.count", -1) do
      delete menusectionlocale_url(@menusectionlocale)
    end

    assert_redirected_to menusectionlocales_url
  end
end
