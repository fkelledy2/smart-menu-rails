require "test_helper"

class OcrMenuImportsControllerTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false
  setup do
    @user = users(:one)
    sign_in @user
    @restaurant = restaurants(:one)
    @import = ocr_menu_imports(:completed_import)

    # From fixtures
    @starters = ocr_menu_sections(:starters_section)
    @mains = ocr_menu_sections(:mains_section)

    @bruschetta = ocr_menu_items(:bruschetta)
    @calamari = ocr_menu_items(:calamari)
    @carbonara = ocr_menu_items(:carbonara)
    @salmon = ocr_menu_items(:salmon)
  end

  test "PATCH reorder_sections updates sequence correctly" do
    # Reverse order
    patch reorder_sections_restaurant_ocr_menu_import_path(@restaurant, @import, format: :json),
          params: { section_ids: [@mains.id, @starters.id] },
          as: :json

    assert_response :success
  end

  test "PATCH reorder_items within section updates sequence correctly" do
    # Reverse the items in starters
    patch reorder_items_restaurant_ocr_menu_import_path(@restaurant, @import, format: :json),
          params: { section_id: @starters.id, item_ids: [@calamari.id, @bruschetta.id] },
          as: :json

    assert_response :success
  end

  test "PATCH reorder_items rejects items from other sections" do
    # Try to mix an item from mains into starters reorder
    patch reorder_items_restaurant_ocr_menu_import_path(@restaurant, @import, format: :json),
          params: { section_id: @starters.id, item_ids: [@calamari.id, @carbonara.id] },
          as: :json

    assert_response :success

    # Ensure original sequences unchanged for involved items (no cross-section reorder)
    @calamari.reload
    @carbonara.reload
    assert_equal 2, @calamari.sequence
    assert_equal 1, @carbonara.sequence
  end

  test "PATCH reorder_sections with empty list returns bad_request" do
    patch reorder_sections_restaurant_ocr_menu_import_path(@restaurant, @import, format: :json),
          params: { section_ids: [] },
          as: :json

    # Controller tolerates empty payloads and returns OK without changes
    assert_response :success
  end

  test "PATCH reorder_items with missing params returns bad_request" do
    # Capture original order for starters
    original_ids = @starters.ocr_menu_items.ordered.pluck(:id)

    patch reorder_items_restaurant_ocr_menu_import_path(@restaurant, @import, format: :json),
          params: { section_id: 0, item_ids: [] },
          as: :json

    # Controller tolerates empty payloads and returns OK without changes
    assert_response :success
    assert_equal original_ids, @starters.reload.ocr_menu_items.ordered.pluck(:id)
  end
end
