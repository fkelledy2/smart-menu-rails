require "test_helper"

class InventoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
    @inventory = inventories(:one)
  end

  test "should get index" do
    get inventories_url
    assert_response :success
  end

  test "should get new" do
    get new_inventory_url
    assert_response :success
  end

  test "should create inventory" do
    assert_difference("Inventory.count") do
      post inventories_url, params: { inventory: { currentinventory: @inventory.currentinventory, menuitem_id: @inventory.menuitem_id, resethour: @inventory.resethour, startinginventory: @inventory.startinginventory } }
    end
    assert_redirected_to edit_menusection_url(@inventory.menusection)
  end

  test "should show inventory" do
    get inventory_url(@inventory)
    assert_response :success
  end

  test "should get edit" do
    get edit_inventory_url(@inventory)
    assert_response :success
  end

  test "should update inventory" do
    patch inventory_url(@inventory), params: { inventory: { currentinventory: @inventory.currentinventory, menuitem_id: @inventory.menuitem_id, resethour: @inventory.resethour, startinginventory: @inventory.startinginventory } }
    assert_redirected_to edit_menusection_url(@inventory.menusection)
  end

  test "should destroy inventory" do
    assert_difference("Inventory.count", 0) do
      delete inventory_url(@inventory)
    end
    assert_redirected_to edit_menusection_url(@inventory.menusection)
  end
end
