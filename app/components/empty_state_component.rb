# frozen_string_literal: true

class EmptyStateComponent < ViewComponent::Base
  ICON_MAP = {
    menu: 'bi-journal-text',
    cart: 'bi-cart3',
    search: 'bi-search',
    table: 'bi-geo-alt',
    staff: 'bi-people',
    order: 'bi-receipt',
    item: 'bi-plus-circle',
    section: 'bi-collection',
    allergen: 'bi-shield-check',
    default: 'bi-inbox',
  }.freeze

  attr_reader :title, :description, :icon, :action_text, :action_url, :action_method, :compact

  # @param title       [String] main heading
  # @param description [String] explanatory subtext
  # @param icon        [Symbol] one of ICON_MAP keys, or a raw bi-* class string
  # @param action_text [String] CTA button label (optional)
  # @param action_url  [String] CTA button URL (optional)
  # @param action_method [Symbol] HTTP method for the CTA (default :get)
  # @param compact     [Boolean] smaller variant for inline use (default false)
  def initialize(title:, description: nil, icon: :default, action_text: nil, action_url: nil, action_method: :get, compact: false)
    @title         = title
    @description   = description
    @icon          = resolve_icon(icon)
    @action_text   = action_text
    @action_url    = action_url
    @action_method = action_method
    @compact       = compact
  end

  private

  def resolve_icon(icon)
    return icon.to_s if icon.to_s.start_with?('bi-')

    ICON_MAP.fetch(icon.to_sym, ICON_MAP[:default])
  end
end
