# frozen_string_literal: true

require 'test_helper'

class SommelierControllerTest < ActionDispatch::IntegrationTest
  def setup
    @smartmenu = smartmenus(:one)
  end

  test 'GET explore_whiskeys succeeds anonymously' do
    get smartmenu_sommelier_explore_whiskeys_path(@smartmenu.slug)
    assert_response :success
  end

  test 'GET pairings succeeds anonymously' do
    menuitem = menuitems(:burger)
    get smartmenu_sommelier_pairings_path(@smartmenu.slug, menuitem_id: menuitem.id)
    assert_response :success
  end
end
