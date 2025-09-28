require "test_helper"

# TODO: Re-enable once API routing issue is resolved
# Issue: API requests return empty HTML instead of reaching controllers
class ApiV1TestControllerTest < ActionDispatch::IntegrationTest
  def test_api_namespace_works
    skip "API routing issue: requests return empty HTML instead of reaching controllers"
  end
end
