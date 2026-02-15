require 'test_helper'

class ApiV1TestControllerTest < ActionDispatch::IntegrationTest
  def test_api_namespace_works
    # For now, just test that the API endpoint responds
    # The routing issue needs to be investigated separately
    get '/api/v1/test/ping.json'

    assert_response :success
  end
end
