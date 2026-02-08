require 'securerandom'

class RestaurantProvisioningService
  def self.call(restaurant:, user:)
    new(restaurant: restaurant, user: user).call
  end

  def initialize(restaurant:, user:)
    @restaurant = restaurant
    @user = user
  end

  def call
    ActiveRecord::Base.transaction do
      ensure_manager_employee
      ensure_default_locale
      ensure_default_table
      ensure_demo_menu
      ensure_default_tax_if_country_present
    end

    true
  end

  private

  attr_reader :restaurant, :user

  def ensure_manager_employee
    return if restaurant.employees.exists?(user: user)

    restaurant.employees.create!(
      user: user,
      name: user.name.presence || 'Manager',
      eid: SecureRandom.hex(6),
      role: :manager,
      status: :active,
    )
  end

  def ensure_default_locale
    active_locales = restaurant.restaurantlocales.where(status: 'active')

    if active_locales.none?
      restaurant.restaurantlocales.create!(
        locale: inferred_locale,
        status: :active,
        dfault: true,
      )
      return
    end

    return if active_locales.exists?(dfault: true)

    locale = active_locales.order(:sequence).first
    locale.update!(dfault: true)
  end

  def inferred_locale
    code = restaurant.country.to_s.strip.upcase
    return 'IT' if code == 'IT'

    'EN'
  end

  def ensure_default_table
    return if restaurant.tablesettings.exists?

    restaurant.tablesettings.create!(
      name: 'Table 1',
      description: 'Default table',
      capacity: 4,
      tabletype: :indoor,
      status: :free,
      archived: false,
      sequence: 1,
    )
  rescue ActiveModel::UnknownAttributeError
    restaurant.tablesettings.create!(
      name: 'Table 1',
      description: 'Default table',
      capacity: 4,
      tabletype: :indoor,
      status: :free,
    )
  end

  def ensure_default_tax_if_country_present
    return if restaurant.country.blank?
    return if restaurant.taxes.exists?

    # Restaurant-services VAT mapping is intentionally config-driven and curated.
    # No tax is created unless country is set.
    # If a rate cannot be inferred, we do not create any default tax.

    rate = vat_restaurant_services_rate_for(restaurant.country)
    return if rate.blank?

    restaurant.taxes.create!(
      name: 'VAT (Restaurant services)',
      taxtype: :local,
      taxpercentage: rate,
      archived: false,
      status: 1,
      sequence: 1,
    )
  rescue StandardError
    nil
  end

  def vat_restaurant_services_rate_for(country_code)
    rates = Rails.application.config_for(:vat_restaurant_services_rates)
    rates[country_code.to_s.upcase]
  rescue StandardError
    nil
  end

  def ensure_demo_menu
    return if restaurant.restaurant_menus.exists?

    DemoMenuService.attach_demo_menu_to_restaurant!(restaurant)
  rescue StandardError
    nil
  end
end
