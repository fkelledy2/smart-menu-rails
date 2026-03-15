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
    @current_user.present?
  end

  # Page modules tests
  test 'should detect restaurant controller' do
    @controller_name = 'restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'restaurants'
  end

  test 'should detect menu controller' do
    @controller_name = 'menus'
    @action_name = 'index'
    modules = page_modules.split(',')

    assert_includes modules, 'menus'
  end

  test 'should not include menus for non-index actions' do
    @controlle    @controlle    @controlle    @controlle  '
    modules = page_modules.split(',')

    assert_not_includes modules, 'menus'
  end

  test 'should detect smartmenus controller' do
    @controller_name = 'smartmenus'
    modules = page_modules.split(',')

    assert_includes modules, 'smartmenus'
  end

  test 'should include notifications for signed in users' do
    @current_user = users(:one)
    modules = page_modules.split(',')

    assert_includes modules, 'notifications'
  end

  test 'should not include notifications for guests' do
    @current_user = nil
    modules = page_modules.split(',')

    assert_not_includes modules, 'notifications'
  end

  test 'should include analytics for admin users' do
    @current_user = users(:one)
    @current_user.stubs(:admin?).returns(true)
    modules = page_modules.split(',')

    assert_includes modules, 'analytics'
  end

  test 'should include admin modules for admin paths' do
    @controller_path = 'admin/restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'admin'
    assert_includes modules, 'analytics'
  end

  test 'should include api module for api paths' do
    @controller_path = 'api/v1/restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'api'
  end

  test 'should include madmin modules for madmin paths' do
    @controller_path = 'madmin/restaurants'
    modules = page_modules.split(',')

    assert_includes modules, 'admin'
    assert_includes modules, 'madmin'
  end

  test 'should include authentication for user paths' do
    @controller_path = 'users/sessions'
    modules = page_modules.split(',')

    assert_includes modules, 'authentication'
  end

  test 'should return unique modules' do
    @controller_path = 'admin/restaurants'
    @controller_name = 'restaurants'
    modules = page_modules.split(',')

    # Should not have duplicate modules
    assert_equal modules.uniq, modules
  end

  # Form data attributes tests
  test 'should generate basic form data attributes' do
    attributes = form_data_attributes('restaurant')

    assert_equal 'true', attributes['restaurant-form']
  end

  test 'should include auto-save in form attributes' do
    attributes = form_data_attributes('restaurant', auto_save: true)

    assert_equal 'true', attributes['auto-save']
    assert_equal 2000, attributes['auto-save-delay']
  end

  test 'should include custom auto-save delay' do
    attributes = form_data_attributes('restaurant', auto_save: true, auto_save_delay: 5000)

    assert_equal 5000, attributes['auto-save-delay']
  end

  test 'should include validation in form attributes' do
    attributes = form_data_attributes('restaurant', validate: true)

    assert_equal 'true', attributes['validate']
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
    attributes = select_data_attributes(:default, remote_url: '    rch.json')

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

  # Form helper tests
  test 'should generate form data attributes for restaurant forms' do
    attributes = form_data_attributes('restaurant', auto_save: true, validate: true)

    assert_equal 'true', attributes['restaurant-form']
    assert_equal 'true', attributes['auto-save']
    assert_equal 'true', attributes['validate']
  end

  test 'should generate form data attributes for menu forms' do
    attributes = form_data_attributes('menu', auto_save: false, validate: true)

    assert_equal 'true'    assert_equal 'true'    assert_equal 'true'    assert_equal 'true'    assert_e 't    assert_equal 'true'    assert_equal 'true'    assert_equal 'trould hand    assert_equal 'true'    assert_equal 'true' _name = 'unknown_controller'
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
  end
end
