require 'test_helper'

class AlcoholOrderEventsFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
    @restaurant = restaurants(:one)
    # Ensure policy allows updates: make the signed-in user the owner
    @restaurant.update!(user: @user)
    # Create an order that belongs to this restaurant to satisfy policy checks
    @order = Ordr.create!(
      restaurant: @restaurant,
      menu: menus(:ordering_menu),
      tablesetting: tablesettings(:table_one),
      status: :opened,
      nett: 0, tip: 0, service: 0, tax: 0, gross: 0,
    )
    @menuitem = menuitems(:one)
    # Ensure the menuitem is alcoholic for this test
    @menuitem.update_columns(abv: 12.5, alcohol_classification: 'wine')
  end

  test 'creates AlcoholOrderEvent when alcoholic item is added' do
    assert_difference -> { AlcoholOrderEvent.count }, +1 do
      post restaurant_ordritems_url(@restaurant), params: {
        ordritem: {
          ordr_id: @order.id,
          menuitem_id: @menuitem.id,
          ordritemprice: 9.99,
          status: 'opened',
        },
      }, as: :json
      assert_response :success
    end

    evt = AlcoholOrderEvent.order(created_at: :desc).first
    assert_equal @order.id, evt.ordr_id
    assert_equal @menuitem.id, evt.menuitem_id
    assert_equal @restaurant.id, evt.restaurant_id
    assert evt.alcoholic
    assert_in_delta 12.5, evt.abv.to_f, 0.01 if evt.abv
  end

  test 'rejects create when requested quantity exceeds available inventory' do
    @order.menu.update!(inventoryTracking: true)
    inventory = @menuitem.inventory || Inventory.create!(
      menuitem: @menuitem,
      startinginventory: 2,
      currentinventory: 2,
      resethour: 0,
      status: :active,
    )
    inventory.update!(startinginventory: 2, currentinventory: 2, resethour: 0, status: :active)

    assert_no_difference -> { Ordritem.count } do
      post restaurant_ordritems_url(@restaurant), params: {
        ordritem: {
          ordr_id: @order.id,
          menuitem_id: @menuitem.id,
          ordritemprice: 9.99,
          status: 'opened',
          quantity: 3,
        },
      }, as: :json
    end

    assert_response :unprocessable_content
    body = JSON.parse(@response.body)
    assert_equal 'insufficient_inventory', body['error']
    assert_equal inventory.currentinventory, body['available']
  end

  test 'rejects quantity increase when requested delta exceeds available inventory' do
    @order.menu.update!(inventoryTracking: true)
    inventory = @menuitem.inventory || Inventory.create!(
      menuitem: @menuitem,
      startinginventory: 5,
      currentinventory: 5,
      resethour: 0,
      status: :active,
    )
    inventory.update!(startinginventory: 5, currentinventory: 1, resethour: 0, status: :active)

    ordritem = Ordritem.create!(
      ordr: @order,
      menuitem: @menuitem,
      status: :opened,
      ordritemprice: 9.99,
      quantity: 2,
      line_key: SecureRandom.uuid,
    )

    assert_no_changes -> { ordritem.reload.quantity } do
      patch restaurant_ordritem_url(@restaurant, ordritem), params: {
        ordritem: {
          quantity: 4,
        },
      }, as: :json
    end

    assert_response :unprocessable_content
    body = JSON.parse(@response.body)
    assert_equal 'insufficient_inventory', body['error']
    assert_equal 1, body['available']
    assert_equal 2, body['requested_increase']
  end

  test 'increasing quantity decrements inventory by delta only' do
    @order.menu.update!(inventoryTracking: true)
    inventory = @menuitem.inventory || Inventory.create!(
      menuitem: @menuitem,
      startinginventory: 10,
      currentinventory: 10,
      resethour: 0,
      status: :active,
    )
    inventory.update!(startinginventory: 10, currentinventory: 4, resethour: 0, status: :active)

    ordritem = Ordritem.create!(
      ordr: @order,
      menuitem: @menuitem,
      status: :opened,
      ordritemprice: 9.99,
      quantity: 2,
      line_key: SecureRandom.uuid,
    )

    patch restaurant_ordritem_url(@restaurant, ordritem), params: {
      ordritem: {
        quantity: 4,
      },
    }, as: :json

    assert_response :success
    assert_equal 4, ordritem.reload.quantity
    assert_equal 2, inventory.reload.currentinventory
  end

  test 'ack_alcohol marks unacknowledged events as acknowledged' do
    # Create two events (unacknowledged)
    2.times do
      AlcoholOrderEvent.create!(
        ordr_id: @order.id,
        ordritem_id: ordritems(:one).id,
        menuitem_id: @menuitem.id,
        restaurant_id: @restaurant.id,
        alcoholic: true,
        age_check_acknowledged: false,
      )
    end

    post ack_alcohol_restaurant_ordr_path(@restaurant, @order), as: :json
    assert_response :success

    AlcoholOrderEvent.where(ordr_id: @order.id).find_each do |evt|
      assert evt.age_check_acknowledged
      assert_not_nil evt.acknowledged_at
    end
  end
end
