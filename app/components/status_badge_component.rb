# frozen_string_literal: true

class StatusBadgeComponent < ViewComponent::Base
  VARIANT_MAP = {
    active: { css: 'text-bg-success', label: 'Active' },
    inactive: { css: 'text-bg-secondary', label: 'Inactive' },
    draft: { css: 'text-bg-warning', label: 'Draft' },
    archived: { css: 'text-bg-danger', label: 'Archived' },
    pending: { css: 'text-bg-info', label: 'Pending' },
    live: { css: 'text-bg-success', label: 'Live' },
    paused: { css: 'text-bg-warning', label: 'Paused' },
  }.freeze

  attr_reader :status, :label, :size, :pill

  # @param status [Symbol] one of VARIANT_MAP keys
  # @param label  [String] override the default label text
  # @param size   [Symbol] :sm (default) or :lg
  # @param pill   [Boolean] use rounded-pill shape (default true)
  def initialize(status:, label: nil, size: :sm, pill: true)
    @status = status.to_sym
    @label  = label || variant[:label]
    @size   = size
    @pill   = pill
  end

  def call
    tag.span(
      label,
      class: css_classes,
      data: { testid: "status-badge-#{status}" },
    )
  end

  private

  def variant
    VARIANT_MAP.fetch(status) { VARIANT_MAP[:inactive] }
  end

  def css_classes
    classes = ['badge', variant[:css]]
    classes << 'rounded-pill' if pill
    classes << 'badge-sm' if size == :sm
    classes << 'badge-lg' if size == :lg
    classes.join(' ')
  end
end
