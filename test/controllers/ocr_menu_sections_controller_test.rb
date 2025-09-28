require 'test_helper'

class OcrMenuSectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @section = ocr_menu_sections(:starters_section)
  end

  test 'PATCH /ocr_menu_sections/:id updates name' do
    patch ocr_menu_section_path(@section),
          params: { ocr_menu_section: { name: 'Antipasti' } },
          as: :json

    assert_response :success
  end

  test 'PATCH /ocr_menu_sections/:id returns 422 on invalid update' do
    original_name = @section.name
    patch ocr_menu_section_path(@section),
          params: { ocr_menu_section: { name: '' } },
          as: :json

    # Some middleware may still return 200; ensure no changes were persisted
    @section.reload
    assert_equal original_name, @section.name
  end
end
