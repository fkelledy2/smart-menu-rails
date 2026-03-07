require 'test_helper'

class RestaurantInsightsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @restaurant = restaurants(:one)
  end

  test 'should get insights page' do
    get "/restaurants/#{@restaurant.id}/insights"
    assert_response :redirect
  end

  test 'should get top performers json' do
    get "/restaurants/#{@restaurant.id}/insights/top_performers.json"
    assert_response :success
    json = response.parsed_body
    assert json.key?('top_performers')
  end

  test 'top performers json reports quantity_sold from ordritem quantity' do
    menuitem = Menuitem.create!(
      name: "Quantity Test #{SecureRandom.hex(4)}",
      description: 'Quantity aggregation test item',
      status: :active,
      sequence: 999,
      calories: 100,
      price: 12.50,
      itemtype: :food,
      menusection: menusections(:one),
    )

    order = Ordr.create!(
      restaurant: @restaurant,
      menu: menus(:one),
      tablesetting: tablesettings(:one),
      status: :ordered,
      orderedAt: Time.current,
      nett: 0,
      tip: 0,
      service: 0,
      tax: 0,
      gross: 0,
    )

    Ordritem.create!(
      ordr: order,
      menuitem: menuitem,
      status: :ordered,
      ordritemprice: 12.50,
      quantity: 4,
      line_key: SecureRandom.uuid,
    )

    Rails.cache.clear

    get "/restaurants/#{@restaurant.id}/insights/top_performers.json"
    assert_response :success

    item = response.parsed_body.fetch('top_performers').find { |row| row['menuitem_name'] == menuitem.name }
    assert_not_nil item
    assert_equal 4, item['quantity_sold'].to_i
    assert_equal 1, item['orders_with_item_count'].to_i
  end

  test 'should get slow movers json' do
    get "/restaurants/#{@restaurant.id}/insights/slow_movers.json"
    assert_response :success
    json = response.parsed_body
    assert json.key?('slow_movers')
  end

  test 'should get prep time bottlenecks json' do
    get "/restaurants/#{@restaurant.id}/insights/prep_time_bottlenecks.json"
    assert_response :success
    json = response.parsed_body
    assert json.key?('prep_time_bottlenecks')
  end

  test 'should get voice triggers json' do
    get "/restaurants/#{@restaurant.id}/insights/voice_triggers.json"
    assert_response :success
    json = response.parsed_body
    assert json.key?('voice_triggers')
  end

  test 'should get abandonment funnel json' do
    get "/restaurants/#{@restaurant.id}/insights/abandonment_funnel.json"
    assert_response :success
    json = response.parsed_body
    assert json.key?('abandonment_funnel')
  end
end
