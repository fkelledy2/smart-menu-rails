require 'test_helper'

class OcrMenuImportsUiTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user

    @restaurant = restaurants(:one)
    @restaurant.update!(currency: 'EUR')
    @import = ocr_menu_imports(:completed_import)

    @starters = ocr_menu_sections(:starters_section)

    @coded_item = OcrMenuItem.create!(
      ocr_menu_section: @starters,
      name: 'Allergen Code Dish',
      description: 'Test',
      price: 1.0,
      allergens: %w[glu mlk],
      sequence: 99,
      is_confirmed: true,
      metadata: {},
    )

    @wine_section = OcrMenuSection.create!(
      ocr_menu_import: @import,
      name: 'Wine',
      sequence: 99,
      is_confirmed: true,
      metadata: {},
    )

    @wine_item = OcrMenuItem.create!(
      ocr_menu_section: @wine_section,
      name: 'Barolo 2018',
      description: 'Nebbiolo',
      price: 12.0,
      allergens: [],
      sequence: 1,
      is_confirmed: true,
      metadata: {},
    )
  end

  test 'food sections hide alcohol UI and allergen codes are expanded' do
    get restaurant_ocr_menu_import_path(@restaurant, @import)
    assert_response :success

    assert_select '.input-group-text', text: '€'

    # Food section should not show alcohol override controls
    assert_select "#section-#{@starters.id}-items [data-role='alcohol-override']", false

    # Wine section should show alcohol override controls
    assert_select "#section-#{@wine_section.id}-items [data-role='alcohol-override']"

    # Allergen codes should display expanded labels
    assert_select '.badge', text: 'Gluten'
    assert_select '.badge', text: 'Milk'
  end
end
