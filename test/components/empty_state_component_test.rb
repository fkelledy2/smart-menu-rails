# frozen_string_literal: true

require "test_helper"

class EmptyStateComponentTest < ViewComponent::TestCase
  def test_renders_title
    render_inline(EmptyStateComponent.new(title: "No items yet"))
    assert_selector ".empty-title", text: "No items yet"
    assert_selector "[data-testid='empty-state']"
  end

  def test_renders_description
    render_inline(EmptyStateComponent.new(title: "Empty", description: "Add your first item"))
    assert_selector ".empty-description", text: "Add your first item"
  end

  def test_hides_description_when_nil
    render_inline(EmptyStateComponent.new(title: "Empty"))
    assert_no_selector ".empty-description"
  end

  def test_renders_icon
    render_inline(EmptyStateComponent.new(title: "Empty", icon: :menu))
    assert_selector ".empty-icon i.bi.bi-journal-text"
  end

  def test_renders_default_icon
    render_inline(EmptyStateComponent.new(title: "Empty"))
    assert_selector ".empty-icon i.bi.bi-inbox"
  end

  def test_renders_custom_icon_string
    render_inline(EmptyStateComponent.new(title: "Empty", icon: "bi-star"))
    assert_selector ".empty-icon i.bi.bi-star"
  end

  def test_renders_action_button
    render_inline(EmptyStateComponent.new(
      title: "No menus",
      action_text: "Create Menu",
      action_url: "/menus/new"
    ))
    assert_selector "a.btn.btn-primary", text: "Create Menu"
    assert_selector "a[href='/menus/new']"
    assert_selector "[data-testid='empty-state-action']"
  end

  def test_hides_action_when_no_url
    render_inline(EmptyStateComponent.new(title: "Empty", action_text: "Click me"))
    assert_no_selector ".empty-action"
  end

  def test_compact_variant
    render_inline(EmptyStateComponent.new(title: "Empty", compact: true))
    assert_selector ".empty-state.empty-state--compact"
  end

  def test_post_action_method
    render_inline(EmptyStateComponent.new(
      title: "Empty",
      action_text: "Generate",
      action_url: "/generate",
      action_method: :post
    ))
    assert_selector "form[action='/generate']"
    assert_selector "button[type='submit']", text: "Generate"
  end
end
