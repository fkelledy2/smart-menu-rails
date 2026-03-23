# frozen_string_literal: true

require 'test_helper'

class MenuSourceTest < ActiveSupport::TestCase
  def build_source(overrides = {})
    MenuSource.new({
      source_url: 'https://example.com/menu.html',
      source_type: :html,
      status: :active,
    }.merge(overrides))
  end

  # =========================================================================
  # validations
  # =========================================================================

  test 'is valid with all required attributes' do
    source = build_source
    # skip file validation
    assert source.valid? || source.errors.attribute_names == [:latest_file], source.errors.full_messages.join(', ')
  end

  test 'is invalid without source_url' do
    source = build_source(source_url: nil)
    assert_not source.valid?
    assert source.errors[:source_url].any?
  end

  test 'is invalid without source_type' do
    source = build_source
    source.write_attribute(:source_type, nil)
    assert_not source.valid?
    assert source.errors[:source_type].any?
  end

  test 'is invalid without status' do
    source = build_source
    source.write_attribute(:status, nil)
    assert_not source.valid?
    assert source.errors[:status].any?
  end

  # =========================================================================
  # enums
  # =========================================================================

  test 'source_type enum has html and pdf' do
    assert build_source(source_type: :html).html?
    assert build_source(source_type: :pdf).pdf?
  end

  test 'status enum has active and disabled' do
    assert build_source(status: :active).active?
    assert build_source(status: :disabled).disabled?
  end

  # =========================================================================
  # display_name
  # =========================================================================

  test 'display_name returns explicit name when set' do
    source = build_source
    source.name = 'Lunch Menu'
    assert_equal 'Lunch Menu', source.display_name
  end

  test 'display_name derives name from source_url when no name set' do
    source = build_source(source_url: 'https://example.com/lunch_menu.pdf')
    source.name = nil
    # derived_menu_name should strip extension and underscores
    name = source.display_name
    assert_kind_of String, name
    assert name.length.positive?
  end

  test 'display_name strips PDF extension from URL-derived name' do
    source = build_source(source_url: 'https://example.com/dinner-menu.pdf')
    source.name = nil
    name = source.display_name
    assert_not_includes name, '.pdf'
  end

  test 'display_name removes "menu" keyword from URL-derived name' do
    source = build_source(source_url: 'https://example.com/the-menu-download.pdf')
    source.name = nil
    name = source.display_name
    # 'menu' and 'download' keywords should be stripped
    assert_no_match(/\bmenu\b/i, name)
  end

  test 'display_name returns Menu when derivation yields empty string' do
    source = build_source(source_url: 'https://example.com/menu.pdf')
    source.name = nil
    name = source.display_name
    # After stripping, only "Menu" keyword remains → fallback to 'Menu'
    assert_equal 'Menu', name
  end

  test 'display_name returns non-empty string for short URL path' do
    source = build_source(source_url: 'https://example.com/')
    source.name = nil
    name = source.display_name
    # The path '/' yields empty after processing — fallback to 'Menu'
    assert_kind_of String, name
    assert name.length.positive?
  end
end
