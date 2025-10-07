require 'test_helper'

class ApiV1VisionTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = JwtService.generate_token_for_user(@user)
  end

  test "vision analyze endpoint requires authentication" do
    post '/api/v1/vision/analyze', 
         headers: { 'Content-Type' => 'application/json' }
    
    assert_response :unauthorized
    assert_includes response.body, 'error'
  end

  test "vision analyze endpoint responds with proper headers" do
    post '/api/v1/vision/analyze',
         headers: { 
           'Authorization' => "Bearer #{@token}",
           'Content-Type' => 'multipart/form-data'
         }
    
    # Should get bad request for missing image, not routing error
    assert_response :bad_request
    assert_equal 'application/json; charset=utf-8', response.content_type
  end

  test "vision analyze endpoint handles invalid image format" do
    # Create a simple text file to simulate invalid format
    file = Tempfile.new(['test', '.txt'])
    file.write('This is not an image')
    file.rewind
    
    uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/plain')
    
    post '/api/v1/vision/analyze',
         params: { image: uploaded_file },
         headers: { 
           'Authorization' => "Bearer #{@token}"
         }
    
    assert_response :unprocessable_entity
    assert_equal 'application/json; charset=utf-8', response.content_type
    
    file.close
    file.unlink
  end
end
