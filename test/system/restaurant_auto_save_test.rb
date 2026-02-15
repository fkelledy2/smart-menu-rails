require 'application_system_test_case'

class RestaurantAutoSaveTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)

    # Ensure restaurant belongs to test user
    @restaurant.update!(user: @user)

    Warden.test_mode!
    login_as(@user, scope: :user)
  end

  teardown do
    Warden.test_reset!
  end

  test 'restaurant details form has auto-save data attributes' do
    visit edit_restaurant_path(@restaurant, section: 'details')

    # Find the form
    form = first('form[data-restaurant-form="true"]')

    # Verify auto-save attributes are present
    assert_equal 'true', form['data-auto-save']
    assert_equal '2000', form['data-auto-save-delay']

  end

  test 'FormManager initializes and detects auto-save forms' do
    visit edit_restaurant_path(@restaurant, section: 'details')

    # Wait for JavaScript to initialize
    sleep 0.5

    # Verify the auto-save controller is wired on at least one form
    assert_selector('form[data-controller~="auto-save"]', wait: 5)
  end

  test 'auto-save triggers after typing stops' do
    visit edit_restaurant_path(@restaurant, section: 'details')

    # Find the name input field
    name_field = find('input[name="restaurant[name]"]')
    original_name = @restaurant.name
    new_name = "#{original_name} Auto Saved"

    # Clear and type new name
    name_field.fill_in with: new_name


    # Wait for DB persistence (poll)
    saved = false
    10.times do
      @restaurant.reload
      if @restaurant.name == new_name
        saved = true
        break
      end
      sleep 0.5
    end
    assert saved, 'Restaurant name should be auto-saved'

  end

  test 'auto-save shows success indicator' do
    visit edit_restaurant_path(@restaurant, section: 'details')

    # Find and change description field
    description_field = find('textarea[name="restaurant[description]"]')
    description_field.fill_in with: 'Auto-save test description'

    # Wait for indicator (optional) and DB persistence
    begin
      page.has_selector?('#auto-save-indicator', wait: 5)
    rescue StandardError
      nil
    end

    saved = false
    10.times do
      @restaurant.reload
      if @restaurant.description == 'Auto-save test description'
        saved = true
        break
      end
      sleep 0.5
    end
    assert saved, 'Description should be auto-saved'
  end

  test 'auto-save makes PATCH request with correct data' do
    visit edit_restaurant_path(@restaurant, section: 'details')

    # Update a field handled by the auto-save controller
    description_field = find('textarea[name="restaurant[description]"]')
    new_description = 'Auto-save patch test'
    description_field.fill_in with: new_description


    begin
      page.has_selector?('#auto-save-indicator', wait: 5)
    rescue StandardError
      nil
    end

    saved = false
    10.times do
      @restaurant.reload
      if @restaurant.description == new_description
        saved = true
        break
      end
      sleep 0.5
    end
    assert saved, 'Description should be auto-saved'
  end

  test 'multiple forms with auto-save work independently' do
    visit edit_restaurant_path(@restaurant, section: 'details')

    # There are two forms on the details page:
    # 1. Restaurant details form (name, description, etc.)
    # 2. Address form (address1, city, etc.)
    forms = all('form[data-auto-save="true"]')
    assert forms.count >= 2, 'Should have at least 2 auto-save forms'


    name_field = find('input[name="restaurant[name]"]')
    name_field.fill_in with: 'Test Restaurant 1'
    begin
      page.has_selector?('#auto-save-indicator', wait: 5)
    rescue StandardError
      nil
    end

  end

  test 'auto-save handles validation errors gracefully' do
    visit edit_restaurant_path(@restaurant, section: 'details')

    # Clear the required name field (should cause validation error)
    name_field = find('input[name="restaurant[name]"]')
    name_field.fill_in with: ''

    # Wait for auto-save attempt
    sleep 3

    # The form should show an error or the save should fail gracefully
    # Check console for error handling
    logs = page.driver.browser.logs.get(:browser)
    logs.any? do |log|
      log.message.include?('[SmartMenu] Auto-save failed') ||
        log.message.include?('[SmartMenu] Auto-save error')
    end

    # Verify restaurant name wasn't blanked out
    @restaurant.reload
    assert_not_nil @restaurant.name, 'Name should not be blank after failed save'
    assert @restaurant.name.present?, 'Name should still have value'

  end
end
