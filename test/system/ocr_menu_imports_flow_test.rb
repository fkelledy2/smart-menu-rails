require 'application_system_test_case'

class OcrMenuImportsFlowTest < ApplicationSystemTestCase
  def setup
    # Authenticate if Devise/Warden is present and a user exists
    if defined?(Warden) && defined?(User) && User.any?
      Warden.test_mode!
      login_as(User.first, scope: :user)
    end

    # Minimal data graph
    @restaurant = Restaurant.create!(name: 'Test Resto', slug: 'test-resto')
    @import = OcrMenuImport.create!(restaurant: @restaurant, name: 'Test Import', status: 'completed')
    @section = OcrMenuSection.create!(ocr_menu_import: @import, name: 'Starters', sequence: 1)
    @item = OcrMenuItem.create!(ocr_menu_section: @section, name: 'Soup', description: 'Tasty', sequence: 1,
                                price: 5.0, allergens: ['gluten'],)
  end

  test 'edit item modal updates DOM without full reload' do
    visit Rails.application.routes.url_helpers.restaurant_ocr_menu_import_path(@restaurant, @import)

    # Ensure the section and item render
    assert_text 'Starters'
    assert_text 'Soup'

    # Open the edit modal by clicking the pencil icon for this item
    find(".item-row[data-item-id='#{@item.id}'] .bi.bi-pencil").click

    # Wait for modal to appear
    assert_selector '#editItemModal', visible: true

    # Fill in new values
    fill_in 'item_name', with: 'Tomato Soup'
    fill_in 'item_description', with: 'Rich and creamy'
    fill_in 'item_price', with: '6.75'

    # Save
    find('#editItemModal .btn.btn-primary', text: /Save Changes/i).click

    # Modal should hide
    assert_no_selector '#editItemModal', visible: true

    # DOM updates in place (no full reload expected here)
    row = find(".item-row[data-item-id='#{@item.id}']")
    within(row) do
      assert_text 'Tomato Soup'
      assert_no_text 'Soup' # old name removed
      # Price updated (allow any currency symbol, just check for amount substring)
      assert_text '6.75'
      assert_text 'Rich and creamy'
    end
  end

  test 'invalid save shows inline errors in modal' do
    visit Rails.application.routes.url_helpers.restaurant_ocr_menu_import_path(@restaurant, @import)

    # Open the edit modal
    find(".item-row[data-item-id='#{@item.id}'] .bi.bi-pencil").click
    assert_selector '#editItemModal', visible: true

    # Make invalid (blank name)
    fill_in 'item_name', with: ''

    # Attempt to save
    find('#editItemModal .btn.btn-primary', text: /Save Changes/i).click

    # Expect inline error alert in modal
    assert_selector '#editItemModal .alert.alert-danger', text: /Unable to save|error/i
  end
end
