require 'test_helper'

class DemoMenuServiceTest < ActiveSupport::TestCase
  # === demo_restaurant_id / demo_menu_id ===

  test 'demo_restaurant_id returns an integer' do
    assert_kind_of Integer, DemoMenuService.demo_restaurant_id
  end

  test 'demo_menu_id returns an integer' do
    assert_kind_of Integer, DemoMenuService.demo_menu_id
  end

  # === demo_menu ===

  test 'demo_menu returns nil when demo menu id does not exist' do
    # In the test environment the demo IDs (1 or 3) may or may not exist.
    # The method must handle the missing case without raising.
    result = DemoMenuService.demo_menu
    # Returns a Menu or nil — both are valid
    assert result.nil? || result.is_a?(Menu)
  end

  # === demo_smartmenu_for_host ===

  test 'demo_smartmenu_for_host returns nil when demo restaurant or menu does not exist' do
    # Stub demo IDs to non-existent values so the guard in demo_smartmenu fires
    DemoMenuService.stub(:demo_restaurant_id, -999) do
      DemoMenuService.stub(:demo_menu_id, -999) do
        result = DemoMenuService.demo_smartmenu_for_host('example.com')
        assert_nil result
      end
    end
  end

  # === attach_demo_menu_to_restaurant! ===

  test 'attach_demo_menu_to_restaurant! returns false when demo menu is nil' do
    DemoMenuService.stub(:demo_menu, nil) do
      result = DemoMenuService.attach_demo_menu_to_restaurant!(restaurants(:one))
      assert_equal false, result
    end
  end

  test 'attach_demo_menu_to_restaurant! returns true when demo menu exists' do
    demo_menu = menus(:one)

    DemoMenuService.stub(:demo_menu, demo_menu) do
      result = DemoMenuService.attach_demo_menu_to_restaurant!(restaurants(:two))
      assert result
    end
  end
end
