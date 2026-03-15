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
  attr_reader :controller_name

  attr_reader :action_name, :controller_path, :current_user

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
  test 'should return correct modules for restaurants controller' do
    @controller_name = 'restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'restaurants'
    assert_includes modules, 'notifications' # user is signed in
  end

  test 'should return correct modules for menus controller' do
    @controller_name = 'menus'
    @action_name = 'index'
    modules = page_modules.split(',')

    assert_includes modules, 'menus'
    assert_includes modules, 'notifications'
  end

  test 'should return correct modules for menus controller edit action' do
    @controller_name = 'menus'
    @action_name = 'edit'
    modules = page_modules.split(',')

    assert_includes modules, 'menus'
  end

  test 'should not include menus module for non-matching actions' do
    @controller_name = 'menus'
    @action_name = 'destroy'
    modules = page_modules.split(',')

    assert_not_includes modules, 'menus'
  end

  test 'should return correct modules for menuitems controller' do
    @controller_name = 'menuitems'
    modules = page_modules.split(',')

    assert_includes modules, 'menuitems'
  end

  test 'should return correct modules for employees controller' do
    @controller_name = 'employees'
    modules = page_modules.split(',')

    assert_includes modules, 'employees'
  end

  test 'should return correct modules for orders controller' do
    @controller_name = 'ordrs'
    modules = page_modules.split(',')

    assert_includes modules, 'orders'
  end

  test 'should return correct modules for onboarding controller' do
    @controller_name = 'onboarding'
    modules = page_modules.split(',')

    assert_includes modules, 'onboarding'
  end

  test 'should return correct modules for admin controllers' do
    @controller_path = 'admin/restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'admin'
    assert_includes modules, 'analytics'
  end

  test 'should return correct modules for api controllers' do
    @controller_path = 'api/restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'api'
  end

  test 'should return correct modules for madmin controllers' do
    @controller_path = 'madmin/restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'admin'
    assert_includes modules, 'madmin'
  end

  test 'should return correct modules for user controllers' do
    @controller_path = 'users/sessions'
    modules = page_modules.split(',')

    assert_includes modules, 'authentication'
  end

  test 'should include analytics for admin users' do
    # Mock admin user
    @current_user.define_singleton_method(:admin?) { true }

    modules = page_modules.split(',')
    assert_includes modules, 'analytics'
  end

  test 'should include notifications for signed in users' do
    modules = page_modules.split(',')

    assert_includes modules, 'notifications'
  end

  test 'should not include notifications for unsigned users' do
    @current_user = nil
    modules = page_modules.split(',')

    assert_not_includes modules, 'notifications'
  end

  test 'should return unique modules' do
    @controller_path = 'admin/restaurants'
    modules = page_modules.split(',')

    # Should not have duplicate modules
    assert_equal modules.uniq, modules
  end

  # Select data attributes tests
  test 'should generate basic select data attributes' do
    attributes = select_data_attributes

    assert_equal 'true', attributes['data-tom-select']
  end

  test 'should generate searchable select attributes' do
    attributes = select_data_attributes(:searchable)

    assert_equal 'true', attributes['data-searchable']
  end

  test 'should generate creatable select attributes' do
    attributes = select_data_attributes(:creatable)

    assert_equal 'true', attributes['data-creatable']
  end

  test 'should generate multi select attributes' do
    attributes = select_data_attributes(:multi)

    expected_options = { plugins: ['remove_button'] }.to_json
    assert_equal expected_options, attributes['data-tom-select-options']
  end

  test 'should generate tags select attributes' do
    attributes = select_data_attributes(:tags)

    assert_equal 'true', attributes['data-creatable']
    expected_options = { create: true, plugins: ['remove_button'] }.to_json
    assert_equal expected_options, attributes['data-tom-select-options']
  end

  test 'should include remote url in select attributes' do
    attributes = select_data_attributes(:default, remote_url: '/search.json')

    assert_equal '/search.json', attributes['data-remote-url']
  end

  test 'should include placeholder in select attributes' do
    attributes = select_data_attributes(:default, placeholder: 'Choose option...')

    assert_equal 'Choose option...', attributes['data-placeholder']
  end

  test 'should merge custom tom select options' do
    custom_options = { maxItems: 5 }
    attributes = select_data_attributes(:multi, tom_select_options: custom_options)

    parsed_options = JSON.parse(attributes['data-tom-select-options'])
    assert_equal ['remove_button'], parsed_options['plugins']
    assert_equal 5, parsed_options['maxItems']
  end

  # Form helper tests - simplified without complex mocking
  test 'should generate form data attributes for restaurant forms' do
    attributes = form_data_attributes('restaurant', auto_save: true, validate: true)

    assert_equal 'true', attributes['restaurant-form']
    assert_equal 'true', attributes['auto-save']
    assert_equal 'true', attributes['validate']
  end

  test 'should generate form data attributes for menu forms' do
    attributes = form_data_attributes('menu', auto_save: false, validate: true)

    assert_equal 'true', attributes['menu-form']
    assert_nil attributes['auto-save']
    assert_equal 'true', attributes['validate']
  end

  # Edge case tests
  test 'should handle unknown controller names' do
    @controller_name = 'unknown_controller'
    modules = page_modules.split(',')

    # Should still include notifications for signed in user
    assert_includes modules, 'notifications'
  end


  test 'should handle empty options for form attributes' do
    attributes = form_data_attributes('test', {})

    assert_equal 'true', attributes['test-form']
    assert_nil attributes['auto-save']
  end

  test 'should handle empty options for select attributes' do
    attributes = select_data_attributes(:default, {})

    assert_equal 'true', attributes['data-tom-select']
    assert_nil attributes['data-remote-url']
  end
end
