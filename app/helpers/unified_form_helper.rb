# ============================================
# UNIFIED FORM HELPER 2025
# Consistent form patterns across all entities
# ============================================

module UnifiedFormHelper
  # Universal form helper that works for ANY entity
  # Provides auto-save and consistent styling
  #
  # Usage:
  #   <%= unified_form_with(@menu) do |form| %>
  #     <%= unified_text_field(form, :name) %>
  #     <%= unified_select(form, :status, Menu.statuses.keys) %>
  #   <% end %>
  def unified_form_with(model, **options, &)
    model.class.name.underscore

    # Determine the correct URL
    url = if model.persisted?
            polymorphic_path(model)
          else
            polymorphic_path([*model_parents(model), model.class])
          end

    defaults = {
      data: {
        controller: 'auto-save',
        'auto-save-url-value': url,
        'auto-save-method-value': model.persisted? ? 'patch' : 'post',
      },
      class: 'unified-form-2025',
    }

    merged_options = options.deep_merge(defaults)

    form_with(model: model, **merged_options, &)
  end

  # Enhanced text field with consistent styling
  def unified_text_field(form, attribute, options = {})
    label = options.delete(:label) || attribute.to_s.humanize
    help_text = options.delete(:help)
    required = options.delete(:required)

    html_options = {
      class: "form-control-2025 #{options.delete(:class)}",
      placeholder: options.delete(:placeholder) || "Enter #{label.downcase}...",
    }.merge(options)

    label_class = 'form-label-2025'
    label_class += ' form-label-2025-required' if required

    content_tag(:div, class: 'form-group-2025') do
      concat form.label(attribute, label, class: label_class)
      concat form.text_field(attribute, html_options)
      concat content_tag(:div, help_text, class: 'form-help-2025') if help_text
    end
  end

  # Enhanced text area with consistent styling
  def unified_text_area(form, attribute, options = {})
    label = options.delete(:label) || attribute.to_s.humanize
    help_text = options.delete(:help)
    required = options.delete(:required)
    rows = options.delete(:rows) || 4

    html_options = {
      class: "form-control-2025 #{options.delete(:class)}",
      placeholder: options.delete(:placeholder) || "Enter #{label.downcase}...",
      rows: rows,
    }.merge(options)

    label_class = 'form-label-2025'
    label_class += ' form-label-2025-required' if required

    content_tag(:div, class: 'form-group-2025') do
      concat form.label(attribute, label, class: label_class)
      concat form.text_area(attribute, html_options)
      concat content_tag(:div, help_text, class: 'form-help-2025') if help_text
    end
  end

  # Enhanced select with TomSelect integration
  def unified_select(form, attribute, choices, options = {})
    label = options.delete(:label) || attribute.to_s.humanize
    help_text = options.delete(:help)
    required = options.delete(:required)
    prompt = options.delete(:prompt) || "Select #{label.downcase}..."

    html_options = {
      class: "form-control-2025 #{options.delete(:class)}",
      data: { controller: 'tom-select' },
    }.merge(options.delete(:html_options) || {})

    label_class = 'form-label-2025'
    label_class += ' form-label-2025-required' if required

    # Format choices for select
    formatted_choices = if choices.is_a?(Hash)
                          choices.map { |k, v| [k.to_s.titleize, v] }
                        elsif choices.is_a?(Array) && choices.first.is_a?(String)
                          choices.map { |c| [c.titleize, c] }
                        else
                          choices
                        end

    content_tag(:div, class: 'form-group-2025') do
      concat form.label(attribute, label, class: label_class)
      concat form.select(attribute, formatted_choices, { prompt: prompt }, html_options)
      concat content_tag(:div, help_text, class: 'form-help-2025') if help_text
    end
  end

  # Checkbox with consistent styling
  def unified_checkbox(form, attribute, options = {})
    label = options.delete(:label) || attribute.to_s.humanize
    help_text = options.delete(:help)

    content_tag(:div, class: 'form-group-2025') do
      content_tag(:div, class: 'checkbox-2025') do
        concat form.check_box(attribute, options)
        concat form.label(attribute, label)
      end.tap do |checkbox|
        concat content_tag(:div, help_text, class: 'form-help-2025') if help_text
      end
    end
  end

  # Form actions (submit/cancel buttons)
  def unified_form_actions(options = {})
    submit_text = options[:submit] || 'Save Changes'
    cancel_path = options[:cancel_path]
    alignment = options[:alignment] || 'end'

    content_tag(:div, class: "form-actions-2025 form-actions-2025-#{alignment}") do
      if cancel_path
        concat link_to('Cancel', cancel_path, class: 'btn-2025 btn-2025-secondary btn-2025-md')
      end
      concat button_tag(submit_text, type: 'submit', class: 'btn-2025 btn-2025-primary btn-2025-md')
    end
  end

  private

  # Helper to determine parent models for nested routes
  def model_parents(model)
    parents = []

    # Handle nested resources based on common patterns
    if model.respond_to?(:menu) && model.menu
      menu = model.menu
      parents << menu.restaurant if menu.respond_to?(:restaurant)
      parents << menu
    elsif model.respond_to?(:restaurant) && model.restaurant
      parents << model.restaurant
    end

    # Handle menusection parent for menuitems
    if model.respond_to?(:menusection) && model.menusection
      menusection = model.menusection
      menu = menusection.menu
      parents << menu.restaurant if menu.respond_to?(:restaurant)
      parents << menu
      parents << menusection
    end

    parents
  end
end
