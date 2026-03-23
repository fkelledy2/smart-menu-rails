# frozen_string_literal: true

require 'test_helper'

class OcrMenuImportsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @restaurant = restaurants(:one)
  end

  test 'GET index redirects unauthenticated to root' do
    get restaurant_ocr_menu_imports_path(@restaurant)
    assert_response :redirect
  end

  test 'GET index succeeds for restaurant owner' do
    sign_in users(:one)
    get restaurant_ocr_menu_imports_path(@restaurant)
    assert_response :success
  end

  test 'GET new redirects unauthenticated to root' do
    get new_restaurant_ocr_menu_import_path(@restaurant)
    assert_response :redirect
  end

  test 'GET new succeeds for restaurant owner' do
    sign_in users(:one)
    get new_restaurant_ocr_menu_import_path(@restaurant)
    assert_response :success
  end
end
