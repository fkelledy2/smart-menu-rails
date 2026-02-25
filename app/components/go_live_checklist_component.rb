# frozen_string_literal: true

class GoLiveChecklistComponent < ViewComponent::Base
  # Renders the restaurant go-live checklist with progress bar and step links.
  # Replaces the inline checklist previously in edit_2025.html.erb.
  #
  # Usage:
  #   render(GoLiveChecklistComponent.new(restaurant: @restaurant, userplan: @userplan))

  attr_reader :restaurant, :userplan

  def initialize(restaurant:, userplan: nil)
    @restaurant = restaurant
    @userplan = userplan
  end

  def render?
    restaurant.onboarding_incomplete?
  end

  def steps
    @steps ||= build_steps
  end

  def completed_count
    steps.count { |s| s[:complete] }
  end

  def total_count
    steps.size
  end

  def percent_complete
    total_count.positive? ? ((completed_count.to_f / total_count) * 100).round : 0
  end

  def all_complete?
    completed_count == total_count
  end

  private

  def build_steps
    [
      { label: 'Restaurant Name', complete: restaurant.name.present?, path: details_path, icon: 'bi-shop' },
      { label: 'Restaurant Currency',  complete: restaurant.currency.present?, path: details_path, icon: 'bi-currency-exchange' },
      { label: 'Restaurant Address',   complete: address_ok?,                  path: details_path, icon: 'bi-geo-alt' },
      { label: 'Restaurant Country',   complete: restaurant.country.present?,  path: details_path, icon: 'bi-globe' },
      { label: 'Add Language',         complete: default_language_ok?,         path: section_path('localization'), icon: 'bi-translate' },
      { label: 'Add Table',            complete: has_table?,                   path: section_path('tables'), icon: 'bi-layout-wtf' },
      { label: 'Add Menu',             complete: has_menu?,                    path: section_path('menus'), icon: 'bi-menu-button-wide' },
      { label: 'Set Merchant Of Record', complete: stripe_connect_enabled?, path: section_path('settings'), icon: 'bi-credit-card' },
      { label: 'Billing Configured', complete: subscription_ok?, path: billing_path, icon: 'bi-receipt', external: true },
    ]
  end

  def address_ok?
    restaurant.address1.present? || restaurant.city.present? || restaurant.postcode.present?
  end

  def default_language_ok?
    restaurant.restaurantlocales.exists?(status: 'active', dfault: true)
  end

  def has_table?
    restaurant.tablesettings.exists?(archived: false)
  end

  def has_menu?
    restaurant.restaurant_menus
      .where.not(status: RestaurantMenu.statuses[:archived])
      .joins(:menu)
      .exists?(menus: { archived: false })
  end

  def stripe_connect_enabled?
    stripe_account&.status.to_s == 'enabled'
  end

  def stripe_account
    @stripe_account ||= restaurant.provider_accounts.find { |a| a.provider.to_s == 'stripe' } ||
                        restaurant.provider_accounts.where(provider: :stripe).first
  end

  def subscription_ok?
    return false unless restaurant.user

    # Userplan table only has: id, user_id, plan_id, created_at, updated_at (no status column).
    # A userplan existing means the user has selected a billing plan.
    restaurant.user.userplans.exists? ||
      restaurant.user.plan.present?
  end

  def details_path
    helpers.edit_restaurant_path(restaurant, section: 'details')
  end

  def section_path(section)
    helpers.edit_restaurant_path(restaurant, section: section)
  end

  def billing_path
    userplan&.id ? helpers.edit_userplan_path(userplan) : nil
  end
end
