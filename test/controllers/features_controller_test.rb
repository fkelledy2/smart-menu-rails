# frozen_string_literal: true

require 'test_helper'

class FeaturesControllerTest < ActionDispatch::IntegrationTest
  test 'GET index returns JSON' do
    get features_path, as: :json
    assert_response :success
    assert_kind_of Array, JSON.parse(response.body)
  end

  test 'GET show returns JSON' do
    feature = features(:one)
    get feature_path(feature), as: :json
    assert_response :success
    assert_equal feature.key, JSON.parse(response.body)['key']
  end
end
