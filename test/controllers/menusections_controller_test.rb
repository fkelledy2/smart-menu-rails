require "test_helper"

class MenusectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @menusection = menusections(:one)
  end

  test "should get index" do
    get menusections_url
    assert_response :success
  end

  test "should get new" do
    get new_menusection_url
    assert_response :success
  end

  test "should create menusection" do
    assert_difference("Menusection.count") do
      post menusections_url, params: { menusection: { description: @menusection.description, image: @menusection.image, menu_id: @menusection.menu_id, name: @menusection.name, sequence: @menusection.sequence, status: @menusection.status } }
    end

    assert_redirected_to menusection_url(Menusection.last)
  end

  test "should show menusection" do
    get menusection_url(@menusection)
    assert_response :success
  end

  test "should get edit" do
    get edit_menusection_url(@menusection)
    assert_response :success
  end

  test "should update menusection" do
    patch menusection_url(@menusection), params: { menusection: { description: @menusection.description, image: @menusection.image, menu_id: @menusection.menu_id, name: @menusection.name, sequence: @menusection.sequence, status: @menusection.status } }
    assert_redirected_to menusection_url(@menusection)
  end

  test "should destroy menusection" do
    assert_difference("Menusection.count", 0) do
      delete menusection_url(@menusection)
    end

    assert_redirected_to menusections_url
  end
end
