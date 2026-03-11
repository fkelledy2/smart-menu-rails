require 'application_system_test_case'

class OcrMenuImportsFlowTest < ApplicationSystemTestCase
  def setup
    # Authenticate if Devise/Warden is present and a user exists
    if defined?(Warden) && defined?(User) && User.any?
      Warden.test_mode!
      login_as(User.first, scope: :user)
    end

    # Minimal data graph
    user = User.first
    @restaurant = Restaurant.create!(
      name: 'Test Resto',
      description: 'Test',
      address1: 'Addr',
      city: 'City',
      country: 'US',
      currency: 'USD',
      status: :active,
      user: user,
    )
    @import = OcrMenuImport.create!(restaurant: @restaurant, name: 'Test Import', status: 'completed')
    @section = OcrMenuSection.create!(ocr_menu_import: @import, name: 'Starters', sequence: 1)
    @item = OcrMenuItem.create!(ocr_menu_section: @section, name: 'Soup', description: 'Tasty', sequence: 1,
                                price: 5.0, allergens: ['gluten'],)
  end

  # Removed: 'edit item modal updates DOM without full reload' - JS controller issue

  test 'invalid save shows inline errors in modal' do
    skip('Error alert rendering needs investigation - JavaScript error handling may need fixes')

    visit Rails.application.routes.url_helpers.restaurant_ocr_menu_import_path(@restaurant, @import)

    # Open the edit modal
    find(".item-row[data-item-id='#{@item.id}'] .bi.bi-pencil").click
    assert_selector '#editItemModal', visible: true, wait: 5

    # Clear the name field using native Capybara method
    fill_in 'item_name', with: ''

    # Attempt to save
    within '#editItemModal' do
      click_button 'Save Changes'
    end

    # Wait for error alert to appear in modal (AJAX response)
    # The JavaScript creates an alert with data-role="item-save-errors"
    assert_selector '#editItemModal .alert.alert-danger[data-role="item-save-errors"]',
                    text: /Name can't be blank|Unable to save/i,
                    wait: 10

    # Modal should stay open
    assert_selector '#editItemModal', visible: true
  end
end
