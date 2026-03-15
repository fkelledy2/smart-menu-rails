require 'test_helper'

class JavascriptHelperAutoSaveTest < ActionView::TestCase
  include JavascriptHelper

  setup do
    @restaurant = restaurants(:one)
  end

  test 'form_data_attributes generates auto-save attributes when enabled' do
    attributes = form_data_attributes('restaurant', auto_save: true)

    # NOTE: Keys don't have 'data-' prefix as form_with adds it
    assert_equal 'true', attributes['restaurant-form']
    assert_equal 'true', attributes['auto-save']
    assert_equal 2000, attributes['auto-save-delay']
  end

  test 'form_data_attributes respects custom auto-save delay' do
    attributes = form_data_attributes('restaurant', auto_save: true, auto_save_delay: 5000)

    assert_equal 'true', attributes['auto-save']
    assert_equal 5000, attributes['auto-save-delay']
  end

  test 'form_data_attributes omits auto-save when disabled' do
    attributes = form_data_attributes('restaurant', auto_save: false)

    assert_equal 'true', attributes['restaurant-form']
    assert_nil attributes['auto-save']
    assert_nil attributes['auto-save-delay']
  end

  test 'restaurant_form_with passes auto-save option correctly' do
    # This test verifies the helper chain works correctly
    # We'll check that the form_with receives the correct data attributes

    form_html = restaurant_form_with(@restaurant, auto_save: true) do |f|
      f.text_field :name
    end

    # Parse the HTML to check attributes
    assert_match(/data-auto-save="true"/, form_html)
    assert_match(/data-auto-save-delay="2000"/, form_html)
  end

  test 'restaurant_form_with works with custom delay' do
    form_html = restaurant_form_with(@restaurant, auto_save: true, auto_save_delay: 3000) do |f|
      f.text_field :name
    end

    assert_match(/data-auto-save="true"/, form_html)
    assert_match(/data-auto-save-delay="3000"/, form_html)
  end

  test 'restaurant_form_with without auto-save does not add attributes' do
    form_html = restaurant_form_with(@restaurant) do |f|
      f.text_field :name
    end

    assert_no_match(/data-auto-save="true"/, form_html)
  end

  test 'restaurant_form_with uses correct form action for existing restaurant' do
    form_html = restaurant_form_with(@restaurant, auto_save: true) do |f|
      f.text_field :name
    end

    # Should use PATCH method for existing restaurant
    assert_match(/method="post"/, form_html)
    assert_match(/<input[^>]*name="_method"[^>]*value="patch"/, form_html)
  end

  test 'form_data_attributes includes both auto-save and validate' do
    attributes = form_data_attributes('restaurant', auto_save: true, validate: true)

    assert_equal 'true', attributes['auto-save']
    assert_equal 'true', attributes['validate']
  end

  test 'menu_form_with also supports auto-save' do
    menu = menus(:one)

    form_html = menu_form_with(menu, auto_save: true, restaurant: menu.restaurant) do |f|
      f.text_field :name
    end

    assert_match(/data-auto-save="true"/, form_html)
    assert_match(/data-auto-save-delay="2000"/, form_html)
  end
end
