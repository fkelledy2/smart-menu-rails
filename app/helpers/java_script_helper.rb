# frozen_string_literal: true

module JavaScriptHelper
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
end
