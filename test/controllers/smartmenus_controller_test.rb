require 'test_helper'

class SmartmenusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @smartmenu = smartmenus(:one)
    @restaurant = restaurants(:one)
    @smartmenu.restaurant = @restaurant
  end

  test 'should show smartmenu' do
    get smartmenu_url(@smartmenu.slug)
    assert_response :success
  end
end
