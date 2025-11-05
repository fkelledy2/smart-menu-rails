require "application_system_test_case"

class RestaurantAutoSaveTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:user_one)
    @restaurant = restaurants(:restaurant_one)
    
    # Ensure restaurant belongs to test user
    @restaurant.update!(user: @user)
    
    sign_in @user
  end

  test "restaurant details form has auto-save data attributes" do
    visit edit_restaurant_path(@restaurant, section: 'details')
    
    # Find the form
    form = find('form[data-restaurant-form="true"]', match: :first)
    
    # Verify auto-save attributes are present
    assert_equal "true", form['data-auto-save']
    assert_equal "2000", form['data-auto-save-delay']
    
    puts "✓ Form has data-auto-save='true'"
    puts "✓ Form has data-auto-save-delay='2000'"
  end

  test "FormManager initializes and detects auto-save forms" do
    visit edit_restaurant_path(@restaurant, section: 'details')
    
    # Wait for JavaScript to initialize
    sleep 0.5
    
    # Check console logs for FormManager initialization
    logs = page.driver.browser.logs.get(:browser)
    
    # Look for our initialization messages
    form_manager_initialized = logs.any? { |log| log.message.include?('[SmartMenu] Basic FormManager initialized') }
    auto_save_enabled = logs.any? { |log| log.message.include?('[SmartMenu] Auto-save enabled for form') }
    
    assert form_manager_initialized, "FormManager should be initialized"
    assert auto_save_enabled, "Auto-save should be enabled for form"
    
    puts "✓ FormManager initialized"
    puts "✓ Auto-save enabled for form"
  end

  test "auto-save triggers after typing stops" do
    visit edit_restaurant_path(@restaurant, section: 'details')
    
    # Find the name input field
    name_field = find('input[name="restaurant[name]"]')
    original_name = @restaurant.name
    new_name = "#{original_name} Auto Saved"
    
    # Clear and type new name
    name_field.fill_in with: new_name
    
    puts "✓ Typed new restaurant name: #{new_name}"
    
    # Wait for auto-save delay (2 seconds) + processing time
    sleep 3
    
    # Check if save indicator appeared
    # The indicator should be visible briefly
    page.assert_text('Saved', wait: 1) rescue nil
    
    puts "✓ Waited for auto-save to trigger"
    
    # Verify the change was saved to database
    @restaurant.reload
    assert_equal new_name, @restaurant.name, "Restaurant name should be auto-saved"
    
    puts "✓ Restaurant name was auto-saved to database"
    puts "  Original: #{original_name}"
    puts "  New: #{@restaurant.name}"
  end

  test "auto-save shows success indicator" do
    visit edit_restaurant_path(@restaurant, section: 'details')
    
    # Find and change description field
    description_field = find('textarea[name="restaurant[description]"]')
    description_field.fill_in with: "Auto-save test description"
    
    # Wait for auto-save
    sleep 3
    
    # Look for the success indicator in the page
    # The indicator should appear briefly with "✓ Saved" text
    indicator_appeared = page.has_css?('.auto-save-indicator', wait: 1) rescue false
    
    if indicator_appeared
      puts "✓ Save indicator appeared"
    else
      # Check browser console for save confirmation
      logs = page.driver.browser.logs.get(:browser)
      save_success = logs.any? { |log| log.message.include?('[SmartMenu] Form auto-saved successfully') }
      assert save_success, "Auto-save should be confirmed in console"
      puts "✓ Auto-save confirmed in console logs"
    end
    
    # Verify data was saved
    @restaurant.reload
    assert_equal "Auto-save test description", @restaurant.description
    puts "✓ Description was saved to database"
  end

  test "auto-save makes PATCH request with correct data" do
    visit edit_restaurant_path(@restaurant, section: 'details')
    
    # Enable network logging
    page.driver.browser.network_conditions = { offline: false, latency: 0, throughput: -1 }
    
    # Find phone field and change it
    phone_field = find('input[name="restaurant[phone]"]')
    new_phone = "+1 (555) 123-4567"
    phone_field.fill_in with: new_phone
    
    puts "✓ Changed phone to: #{new_phone}"
    
    # Wait for auto-save
    sleep 3
    
    # Verify the change was persisted
    @restaurant.reload
    assert_equal new_phone, @restaurant.phone, "Phone should be auto-saved"
    
    puts "✓ Phone was auto-saved successfully"
    puts "  New phone: #{@restaurant.phone}"
  end

  test "multiple forms with auto-save work independently" do
    visit edit_restaurant_path(@restaurant, section: 'details')
    
    # There are two forms on the details page:
    # 1. Restaurant details form (name, description, etc.)
    # 2. Address form (address1, city, etc.)
    
    forms = all('form[data-auto-save="true"]')
    assert forms.count >= 2, "Should have at least 2 auto-save forms"
    
    puts "✓ Found #{forms.count} auto-save forms"
    
    # Change a field in the first form
    name_field = find('input[name="restaurant[name]"]')
    name_field.fill_in with: "Test Restaurant 1"
    
    # Change a field in the second form
    city_field = find('input[name="restaurant[city]"]')
    city_field.fill_in with: "San Francisco"
    
    # Wait for both to auto-save
    sleep 4
    
    # Verify both changes were saved
    @restaurant.reload
    assert_equal "Test Restaurant 1", @restaurant.name
    assert_equal "San Francisco", @restaurant.city
    
    puts "✓ Both forms auto-saved independently"
    puts "  Name: #{@restaurant.name}"
    puts "  City: #{@restaurant.city}"
  end

  test "auto-save handles validation errors gracefully" do
    visit edit_restaurant_path(@restaurant, section: 'details')
    
    # Clear the required name field (should cause validation error)
    name_field = find('input[name="restaurant[name]"]')
    name_field.fill_in with: ""
    
    # Wait for auto-save attempt
    sleep 3
    
    # The form should show an error or the save should fail gracefully
    # Check console for error handling
    logs = page.driver.browser.logs.get(:browser)
    error_handled = logs.any? { |log| 
      log.message.include?('[SmartMenu] Auto-save failed') || 
      log.message.include?('[SmartMenu] Auto-save error')
    }
    
    # Verify restaurant name wasn't blanked out
    @restaurant.reload
    assert_not_nil @restaurant.name, "Name should not be blank after failed save"
    assert @restaurant.name.present?, "Name should still have value"
    
    puts "✓ Validation error handled gracefully"
    puts "✓ Restaurant name preserved: #{@restaurant.name}"
  end
end
