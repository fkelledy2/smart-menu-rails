require 'test_helper'

class Api::V1::VisionControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @mock_image = mock_uploaded_file('image/jpeg')
    @valid_image_params = {
      image: @mock_image,
    }
  end

  # Authentication tests
  test 'should require authentication for analyze' do
    post api_v1_vision_analyze_path, params: @valid_image_params

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  test 'should require authentication for detect menu items' do
    post api_v1_vision_detect_menu_items_path, params: @valid_image_params

    # API requires authentication, expect unauthorized response
    assert_response :unauthorized
  end

  # Route accessibility tests
  test 'should have analyze route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'post', path: '/api/v1/vision/analyze' },
                   { controller: 'api/v1/vision', action: 'analyze', format: :json },)
  end

  test 'should have detect menu items route' do
    # Just verify the route exists (API routes default to JSON format)
    assert_routing({ method: 'post', path: '/api/v1/vision/detect_menu_items' },
                   { controller: 'api/v1/vision', action: 'detect_menu_items', format: :json },)
  end

  # Basic functionality tests
  test 'should handle JSON format requests' do
    post api_v1_vision_analyze_path, params: @valid_image_params, as: :json

    # Should return JSON error response for unauthorized access
    assert_equal 'application/json; charset=utf-8', response.content_type
    assert_response :unauthorized
  end

  test 'should include error details in unauthorized response' do
    post api_v1_vision_analyze_path, params: @valid_image_params, as: :json

    assert_response :unauthorized
    json_response = response.parsed_body
    assert json_response['error'].present?
    assert_equal 'unauthorized', json_response['error']['code']
  end

  private

  # Helper method to create a mock uploaded file
  def mock_uploaded_file(content_type = 'image/jpeg')
    uploaded_file = Object.new
    uploaded_file.define_singleton_method(:respond_to?) { |method| %i[tempfile content_type].include?(method) }
    uploaded_file.define_singleton_method(:content_type) { content_type }
    uploaded_file.define_singleton_method(:tempfile) do
      tempfile = Object.new
      tempfile.define_singleton_method(:path) { '/tmp/test_image.jpg' }
      tempfile
    end
    uploaded_file
  end
end
