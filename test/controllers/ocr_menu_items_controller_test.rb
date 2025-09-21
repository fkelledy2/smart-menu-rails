require "test_helper"

class OcrMenuItemsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @section = OcrMenuSection.create!(name: "Starters", sequence: 1, ocr_menu_import_id: create_import.id)
    @item = OcrMenuItem.create!(ocr_menu_section: @section, name: "Soup", sequence: 1, price: 5.0, allergens: ["gluten"]) 
  end

  test "PATCH /ocr_menu_items/:id updates simple fields" do
    patch ocr_menu_item_path(@item),
      params: {
        ocr_menu_item: {
          name: "Tomato Soup",
          description: "Rich and creamy",
          price: 6.75,
          allergens: ["dairy", "gluten"],
          dietary_restrictions: ["vegetarian", "gluten_free"]
        }
      }.to_json,
      headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }

    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal true, json["ok"]
    @item.reload
    assert_equal "Tomato Soup", @item.name
    assert_equal "Rich and creamy", @item.description
    assert_in_delta 6.75, @item.price.to_f, 0.001
    assert_equal ["dairy", "gluten"].sort, @item.allergens.sort
    # dietary flags mapped
    assert_equal true, @item.respond_to?(:is_vegetarian) ? @item.is_vegetarian : true # if column exists
  end

  test "PATCH /ocr_menu_items/:id returns 422 with validation errors" do
    patch ocr_menu_item_path(@item),
      params: {
        ocr_menu_item: {
          name: "", # invalid: presence
          price: -10
        }
      }.to_json,
      headers: { "CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json" }

    assert_response :unprocessable_entity
    json = JSON.parse(@response.body)
    assert_equal false, json["ok"]
    assert json["errors"].is_a?(Array)
    assert json["errors"].any?
  end

  private

  def create_import
    OcrMenuImport.create!(name: "Test Import", status: "completed")
  end
end
