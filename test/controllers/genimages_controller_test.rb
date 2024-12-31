require "test_helper"

class GenimagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @genimage = genimages(:one)
  end

  test "should get index" do
    get genimages_url
    assert_response :success
  end

  test "should get new" do
    get new_genimage_url
    assert_response :success
  end

  test "should create genimage" do
    assert_difference("Genimage.count") do
      post genimages_url, params: { genimage: { description: @genimage.description, image_data: @genimage.image_data, menu_id: @genimage.menu_id, menuitem_id: @genimage.menuitem_id, menusection_id: @genimage.menusection_id, name: @genimage.name, restaurant_id: @genimage.restaurant_id } }
    end

    assert_redirected_to genimage_url(Genimage.last)
  end

  test "should show genimage" do
    get genimage_url(@genimage)
    assert_response :success
  end

  test "should get edit" do
    get edit_genimage_url(@genimage)
    assert_response :success
  end

  test "should update genimage" do
    patch genimage_url(@genimage), params: { genimage: { description: @genimage.description, image_data: @genimage.image_data, menu_id: @genimage.menu_id, menuitem_id: @genimage.menuitem_id, menusection_id: @genimage.menusection_id, name: @genimage.name, restaurant_id: @genimage.restaurant_id } }
    assert_redirected_to genimage_url(@genimage)
  end

  test "should destroy genimage" do
    assert_difference("Genimage.count", 0) do
      delete genimage_url(@genimage)
    end

    assert_redirected_to genimages_url
  end
end
