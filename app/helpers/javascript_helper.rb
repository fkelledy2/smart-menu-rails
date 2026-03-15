# frozen_string_literal: true

module JavascriptHelper
  # Generate data attributes for select elements
  def select_data_attributes(type = :default, options = {})
    attributes = {
      'data-tom-select' => 'true'
    }
    
    case type.to_sym
    when :searchable
      attributes['data-searchable'] = 'true'
    when :creatable
      attributes['data-creatable'] = 'true'
    when :multi
      attributes['data-tom-select-options'] = { plugins: ['remove_button'] }.to_json
    when :tags
      attributes['data-creatable'] = 'true'
      attributes['data-tom-select-options'] = { 
        create: true, 
        plugins: ['remove_button'] 
      }.to_json
    end
    
    if options[:remote_url]
      attributes['data-remote-url'] = options[:remote_url]
    end
    
    if options[:placeholder]
      attributes['data-placeholder'] = options[:placeholder]
    end
    
    if options[:tom_select_options]
      existing_options = JSON.parse(attributes['data-tom-select-options'] || '{}')
      merged_options = existing_options.merge(options[:tom_select_options])
      attributes['data-tom-select-options'] = merged_options.to_json
    end
    
    attributes
  end

  # Generate data attributes for forms
  def form_data_attributes(type, options = {})
    attributes = {
      "#{type}-form" => 'true'
    }
    
    if options[:auto_save]
      attributes['auto-save'] = 'true'
      attributes['auto-save-delay'] = options[:auto_save_delay] || 2000
    end
    
    if options[:validate]
      attributes['validate'] = 'true'
    end
    
    attributes
  end

  # Helper for restaurant form
  def restaurant_form_with(model, options = {}, &block)
    form_options = {
      auto_save: options.delete(:auto_save) || false,
      validate: options.delete(:validate) || true
    }
    
    attributes = form_data_attributes('restaurant', form_options)
    merged_data = (options[:data] || {}).merge(attributes)
    
    form_with model: model, **options.merge(data: merged_data), &block
  end

  # Helper for menu form
  def menu_form_with(model, options = {}, &block)
    form_options = {
      auto_save: options.delete(:auto_save) || false,
      validate: options.delete(:validate) || true
    }
    
    attributes = form_data_attributes('menu', form_options)
    merged_data = (options[:data] || {}).merge(attributes)
    
    form_with model: model, **options.merge(data: merged_data), &block
  end
end

  # Determine which JavaScript modules should be loaded for the current page
  def page_modules
    modules = []
    
    case controller_name
    when 'restaurants'
      modules << 'restaurants'
    when 'menus'
      modules << 'menus' if action_name.in?(%w[index show edit new])
    when 'menuitems'
      modules << 'menuitems'
    when 'menusections'
      modules << 'menusections'
    when 'employees'
      modules << 'employees'
    when 'ordrs'
      modules << 'orders'
    when 'inventories'
      modules << 'inventories'
    when 'tracks'
      modules << 'tracks'
    when 'smartmenus'
      modules << 'smartmenus'
    when 'onboarding'
      modules << 'onboarding'
    when 'metrics'
      modules << 'analytics'
    when 'payments'
      modules << 'payments'
    when 'plans', 'userplans'
      modules << 'plans'
    end
    
    if controller_path.start_with?('admin/')
      modules << 'admin'
      modules << 'analytics'
    end
    
    if control    if control    if control    if control    iapi'
    end
    
    if controller_path.start_with?('madmin/')
      modules << 'admin'
      modules << 'madmin'
    end
    
    if controller_path.start_with?('users/')
      modules << 'authentication'
    end
    
    modules << 'analytics' if current_user&.admin?
    modules << 'notifications' if user_signed_in?
    
    modules.uniq.join(',')
  end
end
