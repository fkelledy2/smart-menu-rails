require 'test_helper'

class Api::V1::OcrMenuItemSerializerTest < ActiveSupport::TestCase
  setup do
    @item = ocr_menu_items(:bruschetta)
  end

  test 'serializes item with all attributes' do
    serializer = Api::V1::OcrMenuItemSerializer.new(@item)
    result = serializer.as_json

    assert_equal @item.id, result[:id]
    assert_equal @item.name, result[:name]
    assert_equal @item.description, result[:description]
    assert_equal @item.price&.to_f, result[:price]
    assert_equal @item.allergens, result[:allergens]
    assert_equal @item.sequence, result[:sequence]
    assert_equal @item.is_confirmed, result[:is_confirmed]

    # Check dietary restrictions structure
    assert result[:dietary_restrictions].is_a?(Hash)
    assert_includes result[:dietary_restrictions].keys, :is_vegetarian
    assert_includes result[:dietary_restrictions].keys, :is_vegan
    assert_includes result[:dietary_restrictions].keys, :is_gluten_free

    # Check timestamps
    assert result[:created_at].present?
    assert result[:updated_at].present?
  end

  test 'collection serialization' do
    items = [ocr_menu_items(:bruschetta), ocr_menu_items(:calamari)]
    result = Api::V1::OcrMenuItemSerializer.collection(items)

    assert_equal 2, result.length
    assert(result.all?(Hash))
    assert(result.all? { |item| item[:id].present? })
  end
end
