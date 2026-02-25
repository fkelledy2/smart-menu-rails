# frozen_string_literal: true

require 'test_helper'

class ActionMenuComponentTest < ViewComponent::TestCase
  def test_renders_dropdown_trigger
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Edit', url: '/edit', icon: 'bi-pencil')
    end

    assert_selector "[data-testid='action-menu-test-menu']"
    assert_selector "[data-testid='action-menu-trigger-test-menu']"
    assert_selector 'button.dropdown-toggle'
    assert_selector 'i.bi.bi-three-dots-vertical'
  end

  def test_renders_menu_items
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Edit', url: '/edit', icon: 'bi-pencil')
      menu.with_item(label: 'Delete', url: '/delete', variant: :danger, icon: 'bi-trash')
    end

    assert_selector 'ul.dropdown-menu li', count: 2
    assert_selector 'a.dropdown-item', text: 'Edit'
    assert_selector 'a.dropdown-item.text-danger', text: 'Delete'
  end

  def test_renders_divider
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Edit', url: '/edit')
      menu.with_item(label: :divider)
      menu.with_item(label: 'Delete', url: '/delete', variant: :danger)
    end

    assert_selector 'hr.dropdown-divider'
  end

  def test_renders_icons
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Edit', url: '/edit', icon: 'bi-pencil')
    end

    assert_selector 'a.dropdown-item i.bi.bi-pencil'
  end

  def test_disabled_item
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Locked', url: '/locked', disabled: true)
    end

    assert_selector 'a.dropdown-item.disabled', text: 'Locked'
  end

  def test_end_alignment_by_default
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Edit', url: '/edit')
    end

    assert_selector 'ul.dropdown-menu.dropdown-menu-end'
  end

  def test_start_alignment
    render_inline(ActionMenuComponent.new(id: 'test-menu', align: :start)) do |menu|
      menu.with_item(label: 'Edit', url: '/edit')
    end

    assert_selector 'ul.dropdown-menu.dropdown-menu-start'
  end

  def test_turbo_method_data_attribute
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Delete', url: '/delete', method: :delete)
    end

    assert_selector "a[data-turbo-method='delete']", text: 'Delete'
  end

  def test_turbo_confirm_data_attribute
    render_inline(ActionMenuComponent.new(id: 'test-menu')) do |menu|
      menu.with_item(label: 'Delete', url: '/delete', method: :delete, confirm: 'Are you sure?')
    end

    assert_selector "a[data-turbo-confirm='Are you sure?']", text: 'Delete'
  end
end
