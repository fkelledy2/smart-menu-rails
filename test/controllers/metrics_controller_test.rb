require "test_helper"

class MetricsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @metric = metrics(:one)
  end

  test "should get index" do
    get metrics_url
    assert_response :success
  end

  test "should get new" do
    get new_metric_url
    assert_response :success
  end

  test "should create metric" do
    assert_difference("Metric.count") do
      post metrics_url, params: { metric: {  } }
    end
  end

  test "should show metric" do
    get metric_url(@metric)
    assert_response :success
  end

  test "should get edit" do
    get edit_metric_url(@metric)
    assert_response :success
  end

  test "should update metric" do
    patch metric_url(@metric), params: { metric: {  } }
  end

  test "should destroy metric" do
    assert_difference("Metric.count", -1) do
      delete metric_url(@metric)
    end
    assert_redirected_to metrics_url
  end
end
