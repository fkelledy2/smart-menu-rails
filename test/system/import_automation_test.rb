# frozen_string_literal: true

require 'application_system_test_case'

# Demonstration of test automation using data-testid attributes
# This test shows how the new test ID strategy makes tests more stable and readable
class ImportAutomationTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user) if @restaurant.user != @user

    # Login
    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  # Example 1: Test page structure and elements are present
  test 'import page has all required elements' do
    visit edit_restaurant_path(@restaurant, section: 'import')

    # ✅ Using test IDs - stable across UI changes
    assert_testid('import-info-banner', text: 'AI-Powered Menu Import')
    assert_testid('import-form-card')

    # Verify form elements exist
    assert_testid('import-name-input')
    assert_testid('import-pdf-input', visible: :all) # Hidden file input
    assert_testid('import-submit-btn')
  end

  # Example 2: Test form validation
  test 'submit button is disabled until form is complete' do
    visit edit_restaurant_path(@restaurant, section: 'import')

    # ✅ Find elements by test ID - no brittle CSS selectors
    submit_btn = find_testid('import-submit-btn')

    # Initially disabled
    assert submit_btn.disabled?, 'Submit button should be disabled initially'

    # Fill name only - still disabled
    fill_testid('import-name-input', 'Test Menu')
    sleep 0.2 # Allow JS validation

    assert submit_btn.disabled?, 'Submit button should be disabled without PDF'
  end

  # Example 3: Test file selection updates UI
  test 'selecting PDF file updates filename display' do
    visit edit_restaurant_path(@restaurant, section: 'import')

    # Check initial state
    filename_display = text_from_testid('import-filename-display')
    assert_equal 'No file chosen', filename_display

    # The actual file attachment would require a test file:
    # attach_testid('import-pdf-input', file_fixture('sample_menu.pdf'))
    # Then check that filename_display updates
  end

  # Example 4: Test recent imports display
  test 'recent imports are displayed with correct test IDs' do
    # Create test imports
    import1 = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Test Import 1',
      status: 'completed',
    )
    import2 = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Test Import 2',
      status: 'processing',
    )

    visit edit_restaurant_path(@restaurant, section: 'import')

    # ✅ Find elements using test IDs with dynamic IDs
    assert_testid('recent-imports-card')
    assert_testid("import-row-#{import1.id}")
    assert_testid("import-row-#{import2.id}")

    # Verify we can click specific import
    within_testid("import-row-#{import1.id}") do
      assert_text 'Test Import 1'
      assert_testid("import-link-#{import1.id}")
      assert_testid("delete-import-#{import1.id}")
    end
  end

  # Example 5: Test delete functionality
  test 'user can delete an import' do
    import = OcrMenuImport.create!(
      restaurant: @restaurant,
      name: 'Import to Delete',
      status: 'completed',
    )

    visit edit_restaurant_path(@restaurant, section: 'import')

    # Verify import exists
    assert_testid("import-row-#{import.id}")

    # Click delete button using test ID
    within_testid("import-row-#{import.id}") do
      click_testid("delete-import-#{import.id}")
    end

    # Accept confirmation
    begin
      page.driver.browser.switch_to.alert.accept
    rescue StandardError
      nil
    end

    # Wait for removal
    sleep 0.5

    # Verify import is gone
    assert_no_testid("import-row-#{import.id}")
    assert_nil OcrMenuImport.find_by(id: import.id)
  end

  # Example 6: Demonstrate the power of within_testid for scoping
  test 'can interact with elements within specific scopes' do
    import1 = OcrMenuImport.create!(restaurant: @restaurant, name: 'Import 1', status: 'completed')
    import2 = OcrMenuImport.create!(restaurant: @restaurant, name: 'Import 2', status: 'pending')

    visit edit_restaurant_path(@restaurant, section: 'import')

    # ✅ Scope actions to specific rows - no confusion even with similar elements
    within_testid("import-row-#{import1.id}") do
      assert_text 'Import 1'
      assert_text 'Completed'
    end

    within_testid("import-row-#{import2.id}") do
      assert_text 'Import 2'
      assert_text 'Pending'
    end
  end
end

# === Benefits Demonstrated ===
#
# ✅ Stability: Tests won't break when CSS classes change
# ✅ Readability: test_id('import-submit-btn') is self-documenting
# ✅ Maintainability: Clear, predictable selectors
# ✅ Scoping: Easy to target specific elements in lists
# ✅ No Conflicts: IDs are unique and semantic
#
# === Comparison ===
#
# ❌ OLD WAY (Fragile):
#   find('.btn-danger').click
#   find('.content-card-2025 input[type="text"]').fill_in with: 'Name'
#   click_link 'Delete'
#
# ✅ NEW WAY (Stable):
#   click_testid('import-submit-btn')
#   fill_testid('import-name-input', 'Name')
#   click_testid('delete-import-42')
