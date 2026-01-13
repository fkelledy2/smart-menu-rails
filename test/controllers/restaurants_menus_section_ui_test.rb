require 'test_helper'

class RestaurantsMenusSectionUiTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user

    @restaurant = restaurants(:one)

    @other_restaurant = Restaurant.create!(
      user: @user,
      name: 'Other Restaurant',
      description: 'Other description',
      address1: '456 Other St',
      city: 'Other City',
      country: 'Other Country',
      currency: 'EUR',
      status: 'active',
      capacity: 1,
    )

    # Satisfy onboarding guardrails so edit pages don't redirect to required setup sections.
    @restaurant.update!(
      description: @restaurant.description.presence || 'Test restaurant description',
      currency: @restaurant.currency.presence || 'EUR',
      address1: @restaurant.address1.presence || '123 Test St',
    )

    # Complete onboarding prerequisites so RestaurantsController#edit doesn't redirect.
    Tablesetting.create!(
      restaurant: @restaurant,
      name: 'Table 1',
      capacity: 2,
      status: 'free',
      tabletype: 'indoor',
    ) unless @restaurant.tablesettings.any?

    Tax.create!(
      restaurant: @restaurant,
      name: 'VAT',
      taxpercentage: 10.0,
      taxtype: 'local',
      status: 'active',
    ) unless @restaurant.taxes.any?

    Tip.create!(
      restaurant: @restaurant,
      percentage: 10.0,
      status: 'active',
    ) unless @restaurant.tips.any?

    unless @restaurant.restaurantlocales.where(status: 'active', dfault: true).exists?
      Restaurantlocale.create!(
        restaurant: @restaurant,
        locale: 'en',
        status: 'active',
        dfault: true,
      )
    end
  end

  test 'menus section hides sections count and uses share menu placeholder' do
    # Ensure all menus in this list are treated as owned so availability column should be hidden
    @restaurant.restaurant_menus.includes(:menu).each do |rm|
      m = rm.menu
      m.update!(owner_restaurant_id: @restaurant.id)
    end

    get edit_restaurant_path(@restaurant, section: 'menus')
    assert_response :success

    # 1. Sections count removed
    assert_select "tr[data-testid^='menu-row-'] i.bi-grid-3x3", false

    # 2. Share widget placeholder uses localized copy
    assert_select "select[name='target_restaurant_ids[]'] option[selected][disabled]", text: 'Share menu'

    # 3. Availability column hidden when no shared menus
    assert_select 'th', text: 'Availability', count: 0

    # 4. Rows are clickable and explicit edit/view icon is removed
    assert_select "tr[data-testid^='menu-row-'][data-href]", minimum: 1
    assert_select "a[data-testid^='edit-menu-']", false
    assert_select "a[data-testid^='view-menu-']", false
  end

  test 'availability column is shown only when there is at least one shared menu' do
    # Normalize to owned
    @restaurant.restaurant_menus.includes(:menu).each do |rm|
      rm.menu.update!(owner_restaurant_id: @restaurant.id)
    end

    # Create a shared menu row
    shared_menu = Menu.create!(
      name: 'Shared Menu',
      description: 'From another restaurant',
      status: 'active',
      sequence: 999,
      restaurant: restaurants(:two),
      owner_restaurant_id: restaurants(:two).id,
      displayImages: false,
      allowOrdering: false,
      inventoryTracking: false,
      imagecontext: 'x'
    )
    RestaurantMenu.create!(restaurant: @restaurant, menu: shared_menu, status: 'active', sequence: 999)

    get edit_restaurant_path(@restaurant, section: 'menus')
    assert_response :success

    assert_select 'th', text: 'Availability', count: 1
  end

  test 'localization section rows are clickable and use chevron edit affordance' do
    get edit_restaurant_path(@restaurant, section: 'localization')
    assert_response :success

    assert_select "tbody tr.clickable-row[data-href]", minimum: 1
    assert_select "tbody tr.clickable-row a i.bi-chevron-right", minimum: 1
    assert_select "tbody tr.clickable-row a i.bi-pencil", false
  end
end
