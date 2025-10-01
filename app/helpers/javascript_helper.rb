# frozen_string_literal: true

module JavascriptHelper
  # Determine which JavaScript modules should be loaded for the current page
  def page_modules
    modules = []
    
    # Detect based on controller and action
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
    end
    
    # Add modules based on page content
    modules << 'analytics' if current_user&.admin?
    modules << 'notifications' if user_signed_in?
    
    modules.uniq.join(',')
  end

  # Generate data attributes for tables
  def table_data_attributes(type, options = {})
    attributes = {
      'data-tabulator' => 'true',
      'data-table-type' => type
    }
    
    # Add AJAX URL if provided
    if options[:ajax_url]
      attributes['data-ajax-url'] = options[:ajax_url]
    end
    
    # Add pagination settings
    if options[:pagination_size]
      attributes['data-pagination-size'] = options[:pagination_size]
    end
    
    # Add custom configuration
    if options[:config]
      attributes['data-tabulator-config'] = options[:config].to_json
    end
    
    # Add entity context
    if options[:restaurant_id]
      attributes['data-restaurant-id'] = options[:restaurant_id]
    end
    
    if options[:menu_id]
      attributes['data-menu-id'] = options[:menu_id]
    end
    
    attributes
  end

  # Generate data attributes for forms
  def form_data_attributes(type, options = {})
    attributes = {
      "data-#{type}-form" => 'true'
    }
    
    # Add auto-save if enabled
    if options[:auto_save]
      attributes['data-auto-save'] = 'true'
      attributes['data-auto-save-delay'] = options[:auto_save_delay] || 2000
    end
    
    # Add validation if enabled
    if options[:validate]
      attributes['data-validate'] = 'true'
    end
    
    attributes
  end

  # Generate data attributes for select elements
  def select_data_attributes(type = :default, options = {})
    attributes = {
      'data-tom-select' => 'true'
    }
    
    # Set select type configuration
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
    
    # Add remote URL for AJAX loading
    if options[:remote_url]
      attributes['data-remote-url'] = options[:remote_url]
    end
    
    # Add placeholder
    if options[:placeholder]
      attributes['data-placeholder'] = options[:placeholder]
    end
    
    # Add custom options
    if options[:tom_select_options]
      existing_options = JSON.parse(attributes['data-tom-select-options'] || '{}')
      merged_options = existing_options.merge(options[:tom_select_options])
      attributes['data-tom-select-options'] = merged_options.to_json
    end
    
    attributes
  end

  # Helper for restaurant table
  def restaurant_table_tag(options = {})
    default_options = {
      ajax_url: restaurants_path(format: :json),
      pagination_size: 10
    }
    
    attributes = table_data_attributes('restaurant', default_options.merge(options))
    
    content_tag :table, '', 
                id: 'restaurant-table',
                class: 'table table-striped table-hover',
                **attributes
  end

  # Helper for menu table
  def menu_table_tag(restaurant_id = nil, options = {})
    default_options = {
      ajax_url: restaurant_id ? restaurant_menus_path(restaurant_id, format: :json) : menus_path(format: :json),
      pagination_size: 15
    }
    
    if restaurant_id
      default_options[:restaurant_id] = restaurant_id
    end
    
    attributes = table_data_attributes('menu', default_options.merge(options))
    
    content_tag :table, '', 
                id: restaurant_id ? 'restaurant-menu-table' : 'menu-table',
                class: 'table table-striped table-hover',
                **attributes
  end

  # Helper for employee table
  def employee_table_tag(restaurant_id, options = {})
    default_options = {
      ajax_url: restaurant_employees_path(restaurant_id, format: :json),
      restaurant_id: restaurant_id,
      pagination_size: 20
    }
    
    attributes = table_data_attributes('employee', default_options.merge(options))
    
    content_tag :table, '', 
                id: 'restaurant-employee-table',
                class: 'table table-striped table-hover',
                **attributes
  end

  # Helper for restaurant form
  def restaurant_form_with(model, options = {}, &block)
    form_options = {
      auto_save: options.delete(:auto_save) || false,
      validate: options.delete(:validate) || true
    }
    
    attributes = form_data_attributes('restaurant', form_options)
    
    form_with model: model, **options.merge(data: attributes), &block
  end

  # Helper for menu form
  def menu_form_with(model, options = {}, &block)
    form_options = {
      auto_save: options.delete(:auto_save) || false,
      validate: options.delete(:validate) || true
    }
    
    attributes = form_data_attributes('menu', form_options)
    
    form_with model: model, **options.merge(data: attributes), &block
  end

  # Helper for status select
  def status_select(form, field, options = {})
    select_options = {
      placeholder: 'Select status...'
    }.merge(options)
    
    attributes = select_data_attributes(:default, select_options)
    
    form.select field, 
               options_for_select([
                 ['Active', 'active'],
                 ['Inactive', 'inactive'],
                 ['Draft', 'draft']
               ], form.object.send(field)),
               { prompt: select_options[:placeholder] },
               { class: 'form-select', **attributes }
  end

  # Helper for country select
  def country_select(form, field = :country, options = {})
    select_options = {
      placeholder: 'Select country...',
      tom_select_options: { maxOptions: 50 }
    }.merge(options)
    
    attributes = select_data_attributes(:searchable, select_options)
    
    # Common countries list
    countries = [
      ['United States', 'US'],
      ['United Kingdom', 'GB'],
      ['Canada', 'CA'],
      ['Australia', 'AU'],
      ['Germany', 'DE'],
      ['France', 'FR'],
      ['Italy', 'IT'],
      ['Spain', 'ES'],
      ['Netherlands', 'NL'],
      ['Belgium', 'BE'],
      ['Switzerland', 'CH'],
      ['Austria', 'AT'],
      ['Sweden', 'SE'],
      ['Norway', 'NO'],
      ['Denmark', 'DK'],
      ['Finland', 'FI'],
      ['Ireland', 'IE'],
      ['Japan', 'JP'],
      ['South Korea', 'KR'],
      ['Singapore', 'SG'],
      ['New Zealand', 'NZ'],
      ['Mexico', 'MX'],
      ['Brazil', 'BR'],
      ['India', 'IN'],
      ['China', 'CN']
    ]
    
    form.select field,
               options_for_select(countries, form.object.send(field)),
               { prompt: select_options[:placeholder] },
               { class: 'form-select', **attributes }
  end

  # Helper for currency select
  def currency_select(form, field = :currency, options = {})
    select_options = {
      placeholder: 'Select currency...',
      tom_select_options: { maxOptions: 30 }
    }.merge(options)
    
    attributes = select_data_attributes(:searchable, select_options)
    
    # Common currencies list
    currencies = [
      ['US Dollar (USD)', 'USD'],
      ['Euro (EUR)', 'EUR'],
      ['British Pound (GBP)', 'GBP'],
      ['Japanese Yen (JPY)', 'JPY'],
      ['Canadian Dollar (CAD)', 'CAD'],
      ['Australian Dollar (AUD)', 'AUD'],
      ['Swiss Franc (CHF)', 'CHF'],
      ['Chinese Yuan (CNY)', 'CNY'],
      ['Swedish Krona (SEK)', 'SEK'],
      ['Norwegian Krone (NOK)', 'NOK'],
      ['Mexican Peso (MXN)', 'MXN'],
      ['Indian Rupee (INR)', 'INR'],
      ['South Korean Won (KRW)', 'KRW'],
      ['Singapore Dollar (SGD)', 'SGD'],
      ['New Zealand Dollar (NZD)', 'NZD']
    ]
    
    form.select field,
               options_for_select(currencies, form.object.send(field)),
               { prompt: select_options[:placeholder] },
               { class: 'form-select', **attributes }
  end

  # Helper for allergen multi-select
  def allergen_multi_select(form, field = :allergyns, options = {})
    select_options = {
      placeholder: 'Select allergens...'
    }.merge(options)
    
    attributes = select_data_attributes(:multi, select_options)
    
    form.collection_check_boxes field, Allergyn.all, :id, :name do |b|
      content_tag :div, class: 'form-check' do
        b.check_box(class: 'form-check-input', **attributes) +
        b.label(class: 'form-check-label')
      end
    end
  end

  # Helper for tag input
  def tag_input(form, field = :tags, options = {})
    select_options = {
      placeholder: 'Add tags...'
    }.merge(options)
    
    attributes = select_data_attributes(:tags, select_options)
    
    form.text_field field,
                   class: 'form-control',
                   placeholder: select_options[:placeholder],
                   **attributes
  end

  # Helper to include QR code data
  def qr_code_data(restaurant)
    {
      'data-qr-slug' => restaurant.slug,
      'data-qr-host' => request.host,
      'data-qr-icon' => asset_path('qr-icon.png')
    }
  end

  # Helper for notification container
  def notification_container
    content_tag :div, '', 
                class: 'toast-container position-fixed top-0 end-0 p-3',
                style: 'z-index: 1055;'
  end

  # Helper to check if new JS system should be used
  def use_new_js_system?
    # Enable for specific controllers or based on feature flag
    controller_name.in?(%w[
      restaurants menus menuitems menusections employees ordrs inventories
      allergyns announcements contacts dw_orders_mv features genimages home
      ingredients metrics notifications ocr_menu_imports ocr_menu_items ocr_menu_sections
      onboarding payments plans sessions sizes smartmenus tablesettings
      tags taxes testimonials tips tracks userplans
      features_plans menuavailabilities menuitemsizemappings menuparticipants
      menusectionlocales ordractions ordritemnotes ordritems ordrparticipants
      restaurantavailabilities restaurantlocales smartmenus_locale
    ]) ||
    Rails.application.config.respond_to?(:force_new_js_system) && Rails.application.config.force_new_js_system ||
    params[:new_js] == 'true'
  end

  # Helper to conditionally load old or new JS
  def javascript_system_tags
    if use_new_js_system?
      # Add meta tag to signal new system should run
      content_for :head, tag.meta(name: 'js-system', content: 'new')
      
      # Load new modular system
      javascript_importmap_tags + 
      javascript_import_module_tag('application_new')
    else
      # Add meta tag to signal old system
      content_for :head, tag.meta(name: 'js-system', content: 'old')
      
      # Load old system
      javascript_include_tag 'application'
    end
  end

  # Helper for progressive enhancement
  def progressive_enhancement_data
    {
      'data-progressive-enhancement' => 'true',
      'data-fallback-ready' => 'true'
    }
  end
end
