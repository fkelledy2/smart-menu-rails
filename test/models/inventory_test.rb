require 'test_helper'

class InventoryTest < ActiveSupport::TestCase
  def setup
    @inventory = inventories(:one)
    @menuitem = menuitems(:one)
  end

  # === VALIDATION TESTS ===

  test 'should be valid with valid attributes' do
    assert @inventory.valid?
  end

  test 'should require startinginventory' do
    @inventory.startinginventory = nil
    assert_not @inventory.valid?
    assert_includes @inventory.errors[:startinginventory], "can't be blank"
  end

  test 'should require integer startinginventory' do
    @inventory.startinginventory = 10.5
    assert_not @inventory.valid?
    assert_includes @inventory.errors[:startinginventory], 'must be an integer'
  end

  test 'should require currentinventory' do
    @inventory.currentinventory = nil
    assert_not @inventory.valid?
    assert_includes @inventory.errors[:currentinventory], "can't be blank"
  end

  test 'should require integer currentinventory' do
    @inventory.currentinventory = 5.5
    assert_not @inventory.valid?
    assert_includes @inventory.errors[:currentinventory], 'must be an integer'
  end

  test 'should require resethour' do
    @inventory.resethour = nil
    assert_not @inventory.valid?
    assert_includes @inventory.errors[:resethour], "can't be blank"
  end

  test 'should require integer resethour' do
    @inventory.resethour = 12.5
    assert_not @inventory.valid?
    assert_includes @inventory.errors[:resethour], 'must be an integer'
  end

  # === ASSOCIATION TESTS ===

  test 'should belong to menuitem' do
    assert_respond_to @inventory, :menuitem
    assert_instance_of Menuitem, @inventory.menuitem
  end

  # === ENUM TESTS ===

  test 'should have correct status enum values' do
    assert_equal 0, Inventory.statuses[:inactive]
    assert_equal 1, Inventory.statuses[:active]
    assert_equal 2, Inventory.statuses[:archived]
  end

  test 'should allow status changes' do
    @inventory.active!
    assert @inventory.active?

    @inventory.archived!
    assert @inventory.archived?

    @inventory.inactive!
    assert @inventory.inactive?
  end

  # === FACTORY/CREATION TESTS ===

  test 'should create inventory with valid data' do
    inventory = Inventory.new(
      startinginventory: 100,
      currentinventory: 75,
      resethour: 6,
      status: :active,
      menuitem: @menuitem,
    )
    assert inventory.save
    assert_equal 100, inventory.startinginventory
    assert_equal 75, inventory.currentinventory
    assert_equal 6, inventory.resethour
    assert inventory.active?
  end

  test 'should create inventory with zero values' do
    inventory = Inventory.new(
      startinginventory: 0,
      currentinventory: 0,
      resethour: 0,
      status: :inactive,
      menuitem: @menuitem,
    )
    assert inventory.save
    assert_equal 0, inventory.startinginventory
    assert_equal 0, inventory.currentinventory
    assert_equal 0, inventory.resethour
  end

  test 'should create inventory with large values' do
    inventory = Inventory.new(
      startinginventory: 1000,
      currentinventory: 500,
      resethour: 23,
      status: :active,
      menuitem: @menuitem,
    )
    assert inventory.save
    assert_equal 1000, inventory.startinginventory
    assert_equal 500, inventory.currentinventory
    assert_equal 23, inventory.resethour
  end

  # === IDENTITY CACHE TESTS ===

  test 'should have identity cache configured' do
    assert Inventory.respond_to?(:cache_index)
  end
end
