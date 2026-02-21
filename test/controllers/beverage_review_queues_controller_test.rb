require 'test_helper'

class BeverageReviewQueuesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @restaurant = restaurants(:one)
    @restaurant.update!(user: @user) if @restaurant.user != @user
    sign_in @user

    @menu = menus(:one)
    @menu.update!(restaurant: @restaurant) if @menu.restaurant != @restaurant

    @section = menusections(:one)
    @section.update!(menu: @menu) if @section.menu != @menu

    @menuitem = Menuitem.create!(
      menusection: @section,
      name: 'Test Whiskey 12yo',
      description: 'Whiskey',
      price: 10.0,
      calories: 0,
      preptime: 0,
      sequence: 999,
      status: 'active',
      itemtype: 'spirits',
      sommelier_category: 'whiskey',
      sommelier_classification_confidence: 0.9,
      sommelier_parsed_fields: { 'name_raw' => 'Test Whiskey 12yo', 'age_years' => 12 },
      sommelier_parse_confidence: 0.9,
      sommelier_needs_review: true,
    )

    @product = Product.create!(product_type: 'whiskey', canonical_name: 'Test Whiskey 12yo 12yo')
    MenuItemProductLink.create!(menuitem: @menuitem, product: @product, resolution_confidence: 0.9)
  end

  test 'should show beverage review queue' do
    get beverage_review_queue_restaurant_path(@restaurant)
    assert_response :success
    assert_includes response.body, 'Beverage Review Queue'
    assert_includes response.body, @menuitem.name
  end

  test 'review action clears needs_review and can lock link' do
    old = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false

    patch beverage_review_queue_review_restaurant_path(@restaurant, menuitem_id: @menuitem.id, lock: true)
    assert_response :redirect

    @menuitem.reload
    assert_equal false, @menuitem.sommelier_needs_review

    assert_equal true, MenuItemProductLink.where(menuitem_id: @menuitem.id).first.locked
  ensure
    ActionController::Base.allow_forgery_protection = old
  end

  test 'review action merges whiskey staff fields into parsed_fields' do
    old = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false

    patch beverage_review_queue_review_restaurant_path(@restaurant,
      menuitem_id: @menuitem.id,
      whiskey_region: 'islay',
      whiskey_type: 'single_malt',
      distillery: 'Test Distillery',
      cask_type: 'sherry_cask',
      staff_flavor_cluster: 'heavily_peated',
      staff_tasting_note: 'Peaty and medicinal',
      staff_pick: 'true',
    )
    assert_response :redirect

    @menuitem.reload
    assert_equal false, @menuitem.sommelier_needs_review

    parsed = @menuitem.sommelier_parsed_fields
    assert_equal 'islay', parsed['whiskey_region']
    assert_equal 'single_malt', parsed['whiskey_type']
    assert_equal 'Test Distillery', parsed['distillery']
    assert_equal 'sherry_cask', parsed['cask_type']
    assert_equal 'heavily_peated', parsed['staff_flavor_cluster']
    assert_equal 'Peaty and medicinal', parsed['staff_tasting_note']
    assert_equal true, parsed['staff_pick']
    assert parsed['staff_tagged_at'].present?
    assert_equal @user.id, parsed['staff_tagged_by']
    # Pre-existing fields preserved
    assert_equal 12, parsed['age_years']
  ensure
    ActionController::Base.allow_forgery_protection = old
  end
end
