require 'test_helper'

class MetricsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @metric = Metric.create!(
      numberOfRestaurants: 5,
      numberOfMenus: 10,
      numberOfMenuItems: 100,
      numberOfOrders: 50,
      totalOrderValue: 1000.0,
    )
  end

  teardown do
    Metric.delete_all
  end

  test 'should get index' do
    get metrics_url
    assert_response :success
  end

  test 'should get new' do
    get new_metric_url
    assert_response :success
  end

  test 'should get show' do
    get metric_url(@metric)
    assert_response :success
  end

  test 'should get edit' do
    get edit_metric_url(@metric)
    assert_response :success
  end

  test 'should create metric' do
    post metrics_url, params: { metric: {} }
    assert_response :redirect
  end

  test 'should update metric' do
    patch metric_url(@metric), params: { metric: {} }
    assert_response :redirect
  end

  test 'should destroy metric' do
    delete metric_url(@metric)
    assert_response :redirect
  end

  test 'should handle JSON requests' do
    get metrics_url, as: :json
    assert_response :success
  end

  test 'should handle JSON show' do
    get metric_url(@metric), as: :json
    assert_response :success
  end

  test 'should handle cache refresh parameter' do
    get metrics_url, params: { refresh_cache: 'true' }
    assert_response :success
  end

  test 'should handle repeated requests' do
    get metrics_url
    assert_response :success

    get metrics_url
    assert_response :success
  end

  test 'should handle empty parameters' do
    post metrics_url, params: { metric: {} }
    assert_response :redirect
  end

  test 'should filter unknown parameters' do
    post metrics_url, params: {
      metric: {},
      unknown_param: 'should_be_ignored',
    }
    assert_response :redirect
  end

  test 'should access metric actions' do
    get metric_url(@metric)
    assert_response :success

    get new_metric_url
    assert_response :success

    get edit_metric_url(@metric)
    assert_response :success
  end
end
