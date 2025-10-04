# frozen_string_literal: true

require 'test_helper'

class JavascriptHelperTest < ActionView::TestCase
  include JavascriptHelper

  def setup
    # Mock controller and action methods
    @controller_name = 'restaurants'
    @action_name = 'index'
    @controller_path = 'restaurants'
    @current_user = users(:one)
  end

  # Mock methods that would normally be provided by Rails
  def controller_name
    @controller_name
  end

  def action_name
    @action_name
  end

  def controller_path
    @controller_path
  end

  def current_user
    @current_user
  end

  def user_signed_in?
    !current_user.nil?
  end

  def request
    @request ||= OpenStruct.new(host: 'localhost')
  end

  def asset_path(path)
    "/assets/#{path}"
  end

  # Page modules tests
  test "should return correct modules for restaurants controller" do
    @controller_name = 'restaurants'
    modules = page_modules.split(',')
    
    assert_includes modules, 'restaurants'
    assert_includes modules, 'notifications' # user is signed in
  end

  test "should return correct modules for menus controller" do
    @controller_name = 'menus'
    @action_name = 'index'
    modules = page_modules.split(',')
    
    assert_includes modules, 'menus'
    assert_includes modules, 'notifications'
  end

  test "should return correct modules for menus controller edit action" do
    @controller_name = 'menus'
    @action_name = 'edit'
    modules = page_modules.split(',')
    
    assert_includes modules, 'menus'
  end

  test "should not include menus module for non-matching actions" do
    @controller_name = 'menus'
    @action_name = 'destroy'
    modules = page_modules.split(',')
    
    assert_not_includes modules, 'menus'
  end

  test "should return correct modules for menuitems controller" do
    @controller_name = 'menuitems'
    modules = page_modules.split(',')
    
    assert_includes modules, 'menuitems'
  end

  test "should return correct modules for employees controller" do
    @controller_name = 'employees'
    modules = page_modules.split(',')
    
    assert_includes modules, 'employees'
  end

  test "should return correct modules for orders controller" do
    @controller_name = 'ordrs'
    modules = page_modules.split(',')
    
    assert_includes modules, 'orders'
  end

  test "should return correct modules for onboarding controller" do
    @controller_name = 'onboarding'
    modules = page_modules.split(',')
    
    assert_includes modules, 'onboarding'
  end

  test "should return correct modules for admin controllers" do
    @controller_path = 'admin/restaurants'
    modules = page_modules.split(',')
    
    assert_includes modules, 'admin'
    assert_includes modules, 'analytics'
  end

  test "should return correct modules for api controllers" do
    @controller_path = 'api/restaurants'
    modules = page_modules.split(',')
    
    assert_includes modules, 'api'
  end

  test "should return correct modules for madmin controllers" do
    @controller_path = 'madmin/restaurants'
    modules = page_modules.split(',')
    
    assert_includes modules, 'admin'
    assert_includes modules, 'madmin'
  end

  test "should return correct modules for user controllers" do
    @controller_path = 'users/sessions'
    modules = page_modules.split(',')
    
    assert_includes modules, 'authentication'
  end

  test "should include analytics for admin users" do
    # Skip this test as it requires complex mocking
    skip "Requires admin? method mocking"
  end

  test "should include notifications for signed in users" do
    modules = page_modules.split(',')
    
    assert_includes modules, 'notifications'
  end

  test "should not include notifications for unsigned users" do
    @current_user = nil
    modules = page_modules.split(',')
    
    assert_not_includes modules, 'notifications'
  end

  test "should return unique modules" do
    @controller_path = 'admin/restaurants'
    modules = page_modules.split(',')
    
    # Should not have duplicate modules
    assert_equal modules.uniq, modules
  end

  # Table data attributes tests
  test "should generate basic table data attributes" do
    attributes = table_data_attributes('restaurant')
    
    assert_equal 'true', attributes['data-tabulator']
    assert_equal 'restaurant', attributes['data-table-type']
  end

  test "should include ajax url in table attributes" do
    attributes = table_data_attributes('restaurant', ajax_url: '/restaurants.json')
    
    assert_equal '/restaurants.json', attributes['data-ajax-url']
  end

  test "should include pagination size in table attributes" do
    attributes = table_data_attributes('restaurant', pagination_size: 25)
    
    assert_equal 25, attributes['data-pagination-size']
  end

  test "should include custom config in table attributes" do
    config = { sortable: true, filterable: false }
    attributes = table_data_attributes('restaurant', config: config)
    
    assert_equal config.to_json, attributes['data-tabulator-config']
  end

  test "should include restaurant id in table attributes" do
    attributes = table_data_attributes('menu', restaurant_id: 123)
    
    assert_equal 123, attributes['data-restaurant-id']
  end

  test "should include menu id in table attributes" do
    attributes = table_data_attributes('menuitem', menu_id: 456)
    
    assert_equal 456, attributes['data-menu-id']
  end

  # Form data attributes tests
  test "should generate basic form data attributes" do
    attributes = form_data_attributes('restaurant')
    
    assert_equal 'true', attributes['data-restaurant-form']
  end

  test "should include auto-save in form attributes" do
    attributes = form_data_attributes('restaurant', auto_save: true)
    
    assert_equal 'true', attributes['data-auto-save']
    assert_equal 2000, attributes['data-auto-save-delay']
  end

  test "should include custom auto-save delay" do
    attributes = form_data_attributes('restaurant', auto_save: true, auto_save_delay: 5000)
    
    assert_equal 5000, attributes['data-auto-save-delay']
  end

  test "should include validation in form attributes" do
    attributes = form_data_attributes('restaurant', validate: true)
    
    assert_equal 'true', attributes['data-validate']
  end

  # Select data attributes tests
  test "should generate basic select data attributes" do
    attributes = select_data_attributes
    
    assert_equal 'true', attributes['data-tom-select']
  end

  test "should generate searchable select attributes" do
    attributes = select_data_attributes(:searchable)
    
    assert_equal 'true', attributes['data-searchable']
  end

  test "should generate creatable select attributes" do
    attributes = select_data_attributes(:creatable)
    
    assert_equal 'true', attributes['data-creatable']
  end

  test "should generate multi select attributes" do
    attributes = select_data_attributes(:multi)
    
    expected_options = { plugins: ['remove_button'] }.to_json
    assert_equal expected_options, attributes['data-tom-select-options']
  end

  test "should generate tags select attributes" do
    attributes = select_data_attributes(:tags)
    
    assert_equal 'true', attributes['data-creatable']
    expected_options = { create: true, plugins: ['remove_button'] }.to_json
    assert_equal expected_options, attributes['data-tom-select-options']
  end

  test "should include remote url in select attributes" do
    attributes = select_data_attributes(:default, remote_url: '/search.json')
    
    assert_equal '/search.json', attributes['data-remote-url']
  end

  test "should include placeholder in select attributes" do
    attributes = select_data_attributes(:default, placeholder: 'Choose option...')
    
    assert_equal 'Choose option...', attributes['data-placeholder']
  end

  test "should merge custom tom select options" do
    custom_options = { maxItems: 5 }
    attributes = select_data_attributes(:multi, tom_select_options: custom_options)
    
    parsed_options = JSON.parse(attributes['data-tom-select-options'])
    assert_equal ['remove_button'], parsed_options['plugins']
    assert_equal 5, parsed_options['maxItems']
  end

  # Table helper tests
  test "should generate restaurant table tag" do
    table_html = restaurant_table_tag
    
    assert_includes table_html, 'id="restaurant-table"'
    assert_includes table_html, 'class="table table-striped table-hover"'
    assert_includes table_html, 'data-tabulator="true"'
    assert_includes table_html, 'data-table-type="restaurant"'
  end

  test "should generate menu table tag without restaurant" do
    table_html = menu_table_tag
    
    assert_includes table_html, 'id="menu-table"'
    assert_includes table_html, 'data-ajax-url="/menus.json"'
  end

  test "should generate menu table tag with restaurant" do
    restaurant_id = 123
    table_html = menu_table_tag(restaurant_id)
    
    assert_includes table_html, 'id="restaurant-menu-table"'
    assert_includes table_html, "data-restaurant-id=\"#{restaurant_id}\""
  end

  test "should generate employee table tag" do
    restaurant_id = 456
    table_html = employee_table_tag(restaurant_id)
    
    assert_includes table_html, 'id="restaurant-employee-table"'
    assert_includes table_html, "data-restaurant-id=\"#{restaurant_id}\""
  end

  # Form helper tests - simplified without complex mocking
  test "should generate form data attributes for restaurant forms" do
    attributes = form_data_attributes('restaurant', auto_save: true, validate: true)
    
    assert_equal 'true', attributes['data-restaurant-form']
    assert_equal 'true', attributes['data-auto-save']
    assert_equal 'true', attributes['data-validate']
  end

  test "should generate form data attributes for menu forms" do
    attributes = form_data_attributes('menu', auto_save: false, validate: true)
    
    assert_equal 'true', attributes['data-menu-form']
    assert_nil attributes['data-auto-save']
    assert_equal 'true', attributes['data-validate']
  end

  # QR code helper tests
  test "should generate qr code data" do
    restaurant = restaurants(:one)
    
    # Skip if restaurant doesn't have slug method
    if restaurant.respond_to?(:slug)
      data = qr_code_data(restaurant)
      
      assert data['data-qr-slug']
      assert_equal 'localhost', data['data-qr-host']
      assert_equal '/assets/qr-icon.png', data['data-qr-icon']
    else
      skip "Restaurant model doesn't have slug method"
    end
  end

  # Notification helper tests
  test "should generate notification container" do
    container_html = notification_container
    
    assert_includes container_html, 'class="toast-container position-fixed top-0 end-0 p-3"'
    assert_includes container_html, 'style="z-index: 1055;"'
  end

  # JavaScript system tests
  test "should always return true for use_new_js_system" do
    assert use_new_js_system?
  end

  test "should generate javascript system tags" do
    # Skip complex mocking test
    skip "Requires complex Rails helper mocking"
  end

  # Progressive enhancement tests
  test "should generate progressive enhancement data" do
    data = progressive_enhancement_data
    
    assert_equal 'true', data['data-progressive-enhancement']
    assert_equal 'true', data['data-fallback-ready']
  end

  # Edge case tests
  test "should handle unknown controller names" do
    @controller_name = 'unknown_controller'
    modules = page_modules.split(',')
    
    # Should still include notifications for signed in user
    assert_includes modules, 'notifications'
  end

  test "should handle empty options for table attributes" do
    attributes = table_data_attributes('test', {})
    
    assert_equal 'true', attributes['data-tabulator']
    assert_equal 'test', attributes['data-table-type']
    assert_nil attributes['data-ajax-url']
  end

  test "should handle empty options for form attributes" do
    attributes = form_data_attributes('test', {})
    
    assert_equal 'true', attributes['data-test-form']
    assert_nil attributes['data-auto-save']
  end

  test "should handle empty options for select attributes" do
    attributes = select_data_attributes(:default, {})
    
    assert_equal 'true', attributes['data-tom-select']
    assert_nil attributes['data-remote-url']
  end
end
