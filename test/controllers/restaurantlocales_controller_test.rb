require "test_helper"

class RestaurantlocalesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @restaurantlocale = restaurantlocales(:one)
  end

  test "should get index" do
    get restaurantlocales_url
    assert_response :success
  end

  test "should get new" do
    get new_restaurantlocale_url
    assert_response :success
  end

  test "should create restaurantlocale" do
    assert_difference("Restaurantlocale.count") do
      post restaurantlocales_url, params: { restaurantlocale: { locale: @restaurantlocale.locale, restaurant_id: @restaurantlocale.restaurant_id, status: @restaurantlocale.status } }
    end

    assert_redirected_to restaurantlocale_url(Restaurantlocale.last)
  end

  test "should show restaurantlocale" do
    get restaurantlocale_url(@restaurantlocale)
    assert_response :success
  end

  test "should get edit" do
    get edit_restaurantlocale_url(@restaurantlocale)
    assert_response :success
  end

  test "should update restaurantlocale" do
    patch restaurantlocale_url(@restaurantlocale), params: { restaurantlocale: { locale: @restaurantlocale.locale, restaurant_id: @restaurantlocale.restaurant_id, status: @restaurantlocale.status } }
    assert_redirected_to restaurantlocale_url(@restaurantlocale)
  end

  test "should destroy restaurantlocale" do
    assert_difference("Restaurantlocale.count", -1) do
      delete restaurantlocale_url(@restaurantlocale)
    end

    assert_redirected_to restaurantlocales_url
  end
end
