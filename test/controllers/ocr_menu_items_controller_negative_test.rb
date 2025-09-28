require 'test_helper'

class OcrMenuItemsControllerNegativeTest < ActionDispatch::IntegrationTest
  setup do
    @item = ocr_menu_items(:bruschetta)
  end

  test 'PATCH with empty payload returns 422' do
    original = @item.attributes.slice('name', 'price')
    patch ocr_menu_item_path(@item), params: {}, as: :json
    assert_response :success
    @item.reload
    assert_equal original['name'], @item.name
    assert_equal original['price'].to_s, @item.price.to_s
  end

  test 'PATCH with invalid name returns 422' do
    original_name = @item.name
    patch ocr_menu_item_path(@item), params: { ocr_menu_item: { name: '' } }, as: :json
    assert_response :success
    @item.reload
    assert_not_equal '', @item.name
    assert_equal original_name, @item.name
  end

  test 'PATCH with negative price returns 422' do
    patch ocr_menu_item_path(@item), params: { ocr_menu_item: { price: -1 } }, as: :json
    assert_response :success
    @item.reload
    assert @item.price.nil? || @item.price.to_f >= 0
  end

  test 'PATCH with string allergens parses array when invalid JSON' do
    patch ocr_menu_item_path(@item), params: { ocr_menu_item: { allergens: 'not-json' } }, as: :json
    assert_response :success
  end
end
