require 'test_helper'

class OcrMenuImportReorderTest < ActiveSupport::TestCase
  setup do
    @import = ocr_menu_imports(:completed_import)
    @starters = ocr_menu_sections(:starters_section)
    @mains = ocr_menu_sections(:mains_section)

    @bruschetta = ocr_menu_items(:bruschetta)
    @calamari = ocr_menu_items(:calamari)
  end

  test 'reorder_sections! updates sequence and ordered scope' do
    assert_equal [@starters.id, @mains.id], @import.ocr_menu_sections.ordered.pluck(:id)

    @import.reorder_sections!([@mains.id, @starters.id])

    assert_equal [@mains.id, @starters.id], @import.reload.ocr_menu_sections.ordered.pluck(:id)
    assert_equal 2, @starters.reload.sequence
    assert_equal 1, @mains.reload.sequence
  end

  test 'reorder_items! updates sequence within section only' do
    section = @starters
    assert_equal [@bruschetta.id, @calamari.id], section.ocr_menu_items.ordered.pluck(:id)

    @import.reorder_items!(section.id, [@calamari.id, @bruschetta.id])

    assert_equal [@calamari.id, @bruschetta.id], section.reload.ocr_menu_items.ordered.pluck(:id)
    assert_equal 2, @bruschetta.reload.sequence
    assert_equal 1, @calamari.reload.sequence
  end

  test 'reorder_items! raises when mixing items from other sections' do
    other_item = ocr_menu_items(:carbonara)

    assert_raises ActiveRecord::RecordInvalid do
      @import.reorder_items!(@starters.id, [@calamari.id, other_item.id])
    end

    # Ensure original order remains
    assert_equal [@bruschetta.id, @calamari.id], @starters.reload.ocr_menu_items.ordered.pluck(:id)
  end
end
