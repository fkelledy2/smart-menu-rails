# frozen_string_literal: true

module JavascriptHelper
  def select_data_attributes(type = :default, options = {})
    attributes = { 'data-tom-select' => 'true' }
    
    case type.to_sym
    when :searchable
      attributes['data-searchable'] = 'true'
    when :creatable
      attributes['data-creatable'] = 'true'
    when :multi
      attributes['data-tom-select-options'] = { plugins: ['remove_button'] }.to_json
    when :tags
      attributes['data-creatable'] = 'true'
      attributes['data-tom-select-options'] = { create: true, plugins: ['remove_button'] }.to_json
    end
    
    attributes['data-remote-url'] = options[:remote_url] if options[:remote_url]
    attributes['data-placeholder'] = options[:placeholder] if options[:placeholder]
    
    if options[:tom_select_options]
      existing_options = JSON.parse(attributes['data-tom-select-options'] || '{}')
      merged_options = existing_options.merge(options[:tom_select_options])
      attributes['data-tom-select-options'] = merged_options.to_json
    end
    
    attributes
  end

  def form_data_attributes(type, options = {})
    attributes = { "#{type}-form" => 'true' }
    
    if options[:auto_save]
      attributes['auto-save'] = 'true'
      attributes['auto-save-delay'] = options[:auto_save_delay] || 2000
    end
    
    attributes['validate'] = 'true' if options[:validate]
    attributes
  end

  def restaurant_form_with(model, options = {}, &block)
    form_options = {
      auto_save: options.delete(:auto_save) || false,
      auto_save_delay: options.delete(:auto_save_delay),
      validate: options.delete(:validate) || true
    }
    
    attributes = form_data_attributes('restaurant', form_options)
    merged_data = (options[:data] || {}).merge(attributes)
    
    form_with model: model, **options.merge(data: merged_data), &block
  end

  def menu_form_with(model, options = {}, &block)
    form_options = {
      auto_save: options.delete(:auto_save) || false,
      auto_save_delay: options.delete(:auto_save_delay),
      validate: options.delete(:validate) || true
    }
    
    attributes = form_data_attributes('menu', form_options)
    merged_data = (options[:data] || {}).merge(attributes)
    
    form_with model: model, **options.merge(data: merged_data), &block
  end

  def page_modules
    modules = []
    
    case controller_name
    when 'restaurants' then modules << 'restaurants'
    when 'menus' then modules << 'menus' if action_name.in?(%w[index show edit new])
    when 'menuitems' then modules << 'menuitems'
    when 'menusections' then modules << 'menusections'
    when 'employees' then modules << 'employees'
    when 'ordrs' then modules << 'orders'
    when 'inventories' then modules << 'inventories'
    when 'tracks' then modules << 'tracks'
    when 'smartmenus' then modules << 'smartmenus'
    when 'onboarding' then modules << 'onboarding'
    when 'metrics' then modules << 'analytics'
    when 'payments' then modules << 'payments'
    when 'plans', 'userplans' then modules << 'plans'
    end
    
    modules << 'admin' << 'analytics' if controller_path.start_with?('admin/')
    modules << 'api' if controller_path.start_with?('api/')
    modules << 'admin' << 'madmin' if controller_path.start_with?('madmin/')
    modules << 'authentication' if controller_path.start_with?('users/')
    modules << 'analytics' if current_user&.admin?
    modules << 'notifications' if user_signed_in?
    
    modules.uniq.join(',')
  end
end
