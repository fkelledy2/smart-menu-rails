# frozen_string_literal: true

require 'test_helper'

class StatusBadgeComponentTest < ViewComponent::TestCase
  def test_renders_active_badge
    render_inline(StatusBadgeComponent.new(status: :active))
    assert_selector 'span.badge.text-bg-success', text: 'Active'
    assert_selector "[data-testid='status-badge-active']"
  end

  def test_renders_inactive_badge
    render_inline(StatusBadgeComponent.new(status: :inactive))
    assert_selector 'span.badge.text-bg-secondary', text: 'Inactive'
    assert_selector "[data-testid='status-badge-inactive']"
  end

  def test_renders_draft_badge
    render_inline(StatusBadgeComponent.new(status: :draft))
    assert_selector 'span.badge.text-bg-warning', text: 'Draft'
  end

  def test_renders_archived_badge
    render_inline(StatusBadgeComponent.new(status: :archived))
    assert_selector 'span.badge.text-bg-danger', text: 'Archived'
  end

  def test_renders_pending_badge
    render_inline(StatusBadgeComponent.new(status: :pending))
    assert_selector 'span.badge.text-bg-info', text: 'Pending'
  end

  def test_custom_label_overrides_default
    render_inline(StatusBadgeComponent.new(status: :active, label: 'Online'))
    assert_selector 'span.badge.text-bg-success', text: 'Online'
  end

  def test_pill_shape_by_default
    render_inline(StatusBadgeComponent.new(status: :active))
    assert_selector 'span.badge.rounded-pill'
  end

  def test_no_pill_when_disabled
    render_inline(StatusBadgeComponent.new(status: :active, pill: false))
    assert_no_selector 'span.badge.rounded-pill'
  end

  def test_large_size
    render_inline(StatusBadgeComponent.new(status: :active, size: :lg))
    assert_selector 'span.badge.badge-lg'
  end

  def test_unknown_status_falls_back_to_inactive
    render_inline(StatusBadgeComponent.new(status: :unknown))
    assert_selector 'span.badge.text-bg-secondary'
  end

  def test_accepts_string_status
    render_inline(StatusBadgeComponent.new(status: 'active'))
    assert_selector 'span.badge.text-bg-success', text: 'Active'
  end
end
