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
