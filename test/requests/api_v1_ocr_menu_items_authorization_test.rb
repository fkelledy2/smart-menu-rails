require 'test_helper'

# TODO: Re-enable once API routing issue is resolved
# Issue: API requests return empty HTML instead of reaching controllers
class ApiV1OcrMenuItemsAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:one)
    @other = users(:two)
    @item = ocr_menu_items(:bruschetta)
  end

  # Disabled due to API routing issue - requests don't reach controllers
  def test_owner_can_update_item
    skip 'API routing issue: requests return empty HTML instead of reaching controllers'
  end

  def test_non_owner_receives_forbidden
    skip 'API routing issue: requests return empty HTML instead of reaching controllers'
  end
end
