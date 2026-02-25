# frozen_string_literal: true

class ActionMenuComponent < ViewComponent::Base
  renders_many :items, 'ActionItem'

  attr_reader :id, :align, :size

  # @param id    [String] unique DOM id for the dropdown (required for accessibility)
  # @param align [Symbol] :end (default) or :start — dropdown alignment
  # @param size  [Symbol] :sm (default) or :lg
  def initialize(id:, align: :end, size: :sm)
    @id    = id
    @align = align
    @size  = size
  end

  # Individual menu item slot
  class ActionItem < ViewComponent::Base
    attr_reader :label, :url, :icon, :method, :variant, :confirm, :turbo_frame, :disabled

    def initialize(label:, url: '#', icon: nil, method: :get, variant: :default, confirm: nil, turbo_frame: nil, disabled: false)
      @label       = label
      @url         = url
      @icon        = icon
      @method      = method
      @variant     = variant
      @confirm     = confirm
      @turbo_frame = turbo_frame
      @disabled    = disabled
    end

    def call
      # Rendered by parent template
      content
    end

    def divider?
      label == :divider
    end

    def css_class
      base = 'dropdown-item'
      base += ' text-danger' if variant == :danger
      base += ' disabled' if disabled
      base
    end

    def data_attrs
      attrs = {}
      attrs[:turbo_method] = method if method != :get
      attrs[:turbo_confirm] = confirm if confirm.present?
      attrs[:turbo_frame] = turbo_frame if turbo_frame.present?
      attrs[:testid] = "action-menu-item-#{label.to_s.parameterize}"
      attrs
    end
  end
end
