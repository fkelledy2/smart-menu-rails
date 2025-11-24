require 'test_helper'

class AlcoholOrderEventsFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
    @restaurant = restaurants(:one)
    @order = ordrs(:one)
    @menuitem = menuitems(:one)
    # Ensure the menuitem is alcoholic for this test
    @menuitem.update_columns(alcoholic: true, abv: 12.5, alcohol_classification: 'wine') if @menuitem.respond_to?(:alcoholic)
  end

  test 'creates AlcoholOrderEvent when alcoholic item is added' do
    assert_difference -> { AlcoholOrderEvent.count }, +1 do
      post restaurant_ordritems_url(@restaurant), params: {
        ordritem: {
          ordr_id: @order.id,
          menuitem_id: @menuitem.id,
          ordritemprice: 9.99,
          status: 'pending',
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
