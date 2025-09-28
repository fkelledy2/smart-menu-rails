require 'test_helper'

class OcrMenuImportReorderEdgeTest < ActiveSupport::TestCase
  setup do
    @import = ocr_menu_imports(:completed_import)
    @starters = ocr_menu_sections(:starters_section)
    @mains = ocr_menu_sections(:mains_section)
  end

  test 'reorder_sections! raises on blank ids' do
    assert_raises ArgumentError do
      @import.reorder_sections!([])
    end
  end

  test 'reorder_sections! raises when unknown id given' do
    bad_id = 9_999_999
    assert_raises ActiveRecord::RecordInvalid do
      @import.reorder_sections!([@starters.id, bad_id])
    end
  end

  test 'reorder_items! raises on blank section or ids' do
    assert_raises ArgumentError do
      @import.reorder_items!(nil, [])
    end
  end

  test 'reorder_items! raises when section not found' do
    missing_section = 9_999_999
    assert_raises ActiveRecord::RecordNotFound do
      @import.reorder_items!(missing_section, [1, 2])
    end
  end

  test 'reorder_items! raises when ids include item from other section' do
    other_item = ocr_menu_items(:carbonara)
    assert_raises ActiveRecord::RecordInvalid do
      @import.reorder_items!(@starters.id, [other_item.id])
    end
  end
end
