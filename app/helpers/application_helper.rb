module ApplicationHelper
  include Testable

  # Enhanced restaurant context helper for JavaScript
  def restaurant_context_data(restaurant = nil)
    # Try to determine restaurant from various sources
    restaurant ||= @restaurant ||
                   @menu&.restaurant ||
                   @menuitem&.menusection&.menu&.restaurant ||
                   @menusection&.menu&.restaurant ||
                   current_user&.restaurants&.first

    return {} unless restaurant

    {
      'data-restaurant-id' => restaurant.id,
      'data-restaurant-name' => restaurant.name,
      'data-restaurant-slug' => restaurant.respond_to?(:slug) ? restaurant.slug : nil,
    }
  end

  # Add restaurant context meta tags
  def restaurant_context_meta_tags(restaurant = nil)
    restaurant ||= @restaurant ||
                   @menu&.restaurant ||
                   @menuitem&.menusection&.menu&.restaurant ||
                   @menusection&.menu&.restaurant

    return '' unless restaurant

    content_for :head do
      tags = []
      tags << tag.meta(name: 'restaurant-id', content: restaurant.id)
      tags << tag.meta(name: 'current-restaurant', content: restaurant.id)
      tags << tag.meta(property: 'restaurant:id', content: restaurant.id)
      if restaurant.respond_to?(:currency) && restaurant.currency.present?
        tags << tag.meta(name: 'restaurant-currency', content: restaurant.currency)
      end
      safe_join(tags)
    end
  end

  # JavaScript context initialization
  def restaurant_context_script(restaurant = nil)
    restaurant ||= @restaurant ||
                   @menu&.restaurant ||
                   @menuitem&.menusection&.menu&.restaurant ||
                   @menusection&.menu&.restaurant

    return '' unless restaurant

    javascript_tag do
      raw <<~JS
        // Set global restaurant context for JavaScript
        window.currentRestaurant = {
          id: #{restaurant.id.to_json},
          name: #{restaurant.name.to_json},
          slug: #{(restaurant.respond_to?(:slug) ? restaurant.slug : nil).to_json}
        };

        // Store in session storage for persistence
        try {
          sessionStorage.setItem('currentRestaurantId', #{restaurant.id.to_json});
        } catch(e) {
          console.warn('Unable to store restaurant context:', e);
        }
      JS
    end
  end

  # Enhanced body tag with restaurant context
  def body_with_restaurant_context(restaurant = nil, **options)
    # Merge restaurant context data with any existing data attributes
    restaurant_data = restaurant_context_data(restaurant)
    options[:data] = (options[:data] || {}).merge(restaurant_data.transform_keys do |k|
      k.delete_prefix('data-').tr('-', '_')
    end)

    tag.body(options) do
      yield if block_given?
    end
  end

  # Safely render HTML content from translations
  # This method should be used when translation values contain HTML that needs to be rendered
  def t_html(key, **options)
    k = key.to_s
    return raw('') if k.blank?

    opts = options
    value = I18n.t(k, **opts.merge(default: nil))
    if value.blank? || value.to_s.start_with?('translation missing:')
      value = I18n.t(k, **opts.merge(locale: I18n.default_locale, default: k))
    end

    raw value
  end

  # Alternative method name for clarity
  alias translate_html t_html

  # Get Bootstrap icon class for currency
  def currency_icon(currency_code)
    case currency_code&.upcase
    when 'USD'
      'bi-currency-dollar'
    when 'EUR'
      'bi-currency-euro'
    when 'GBP'
      'bi-currency-pound'
    when 'JPY', 'CNY'
      'bi-currency-yen'
    else
      'bi-cash-coin' # Generic fallback
    end
  end

  def build_number
    release = ENV['HEROKU_RELEASE_VERSION'] || ENV.fetch('HEROKU_RELEASE_NUMBER', nil)
    return nil if release.blank?

    date_str = if ENV['HEROKU_RELEASE_CREATED_AT']
                 Time.parse(ENV['HEROKU_RELEASE_CREATED_AT']).utc.to_date.strftime('%Y%m%d')
               else
                 Time.now.utc.to_date.strftime('%Y%m%d')
               end

    "#{date_str}-#{release}"
  rescue ArgumentError
    "#{Time.now.utc.to_date.strftime('%Y%m%d')}-#{release}"
  end

  # Resolve preferred locale from participant chain
  # Returns the first non-nil preferredlocale from the chain
  def resolve_participant_locale(ordrparticipant = nil, menuparticipant = nil)
    ordrparticipant ||= @ordrparticipant
    menuparticipant ||= @menuparticipant

    ordrparticipant&.preferredlocale || menuparticipant&.preferredlocale || I18n.default_locale
  end

  # Localize a name using resolved participant locale
  def localised_name(entity, ordrparticipant = nil, menuparticipant = nil)
    return entity.name unless entity.respond_to?(:localised_name)

    locale = resolve_participant_locale(ordrparticipant, menuparticipant)
    entity.localised_name(locale)
  end

  # Localize a description using resolved participant locale
  def localised_description(entity, ordrparticipant = nil, menuparticipant = nil)
    return entity.description unless entity.respond_to?(:localised_description)

    locale = resolve_participant_locale(ordrparticipant, menuparticipant)
    entity.localised_description(locale)
  end
end
