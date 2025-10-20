require 'test_helper'

class OrdrTest < ActiveSupport::TestCase
  def setup
    @ordr = ordrs(:one)
    @restaurant = restaurants(:one)
    @menu = menus(:one)
    @tablesetting = tablesettings(:one)
  end

  # Association tests
  test 'should belong to restaurant' do
    assert_respond_to @ordr, :restaurant
    assert_not_nil @ordr.restaurant
  end

  test 'should belong to menu' do
    assert_respond_to @ordr, :menu
    assert_not_nil @ordr.menu
  end

  test 'should belong to tablesetting' do
    assert_respond_to @ordr, :tablesetting
    assert_not_nil @ordr.tablesetting
  end

  test 'should belong to employee optionally' do
    assert_respond_to @ordr, :employee
    # Employee can be nil for customer orders
  end

  test 'should have many ordritems' do
    assert_respond_to @ordr, :ordritems
  end

  test 'should have many ordrparticipants' do
    assert_respond_to @ordr, :ordrparticipants
  end

  test 'should have many ordractions' do
    assert_respond_to @ordr, :ordractions
  end

  # AASM State Machine tests
  test 'should have opened as initial state' do
    ordr = Ordr.new(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )
    assert ordr.opened?
  end

  test 'should transition from opened to ordered' do
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )

    assert ordr.opened?
    ordr.order!
    assert ordr.ordered?
  end

  test 'should transition from opened to billrequested' do
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )

    assert ordr.opened?
    ordr.requestbill!
    assert ordr.billrequested?
  end

  test 'should transition from ordered to billrequested' do
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )

    ordr.order!
    assert ordr.ordered?
    ordr.requestbill!
    assert ordr.billrequested?
  end

  test 'should transition from billrequested to paid' do
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )

    ordr.requestbill!
    assert ordr.billrequested?
    ordr.paybill!
    assert ordr.paid?
  end

  test 'should transition from paid to closed' do
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )

    ordr.requestbill!
    ordr.paybill!
    assert ordr.paid?
    ordr.close!
    assert ordr.closed?
  end

  # Enum tests
  test 'should have status enum' do
    assert_respond_to @ordr, :status
    assert_respond_to @ordr, :opened?
    assert_respond_to @ordr, :ordered?
    assert_respond_to @ordr, :delivered?
    assert_respond_to @ordr, :billrequested?
    assert_respond_to @ordr, :paid?
    assert_respond_to @ordr, :closed?
  end

  # Business logic tests
  test 'grossInCents should convert gross to cents' do
    @ordr.update!(gross: 25.50)
    assert_equal 2550, @ordr.grossInCents
  end

  test 'grossInCents should handle zero' do
    @ordr.update!(gross: 0.0)
    assert_equal 0, @ordr.grossInCents
  end

  test 'orderedItems should return items with status 20' do
    # Create test ordritems with different statuses
    menuitem = menuitems(:one)

    ordered_item = @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :ordered,
      ordritemprice: 10.0,
    )

    opened_item = @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :opened,
      ordritemprice: 15.0,
    )

    ordered_items = @ordr.orderedItems
    assert_includes ordered_items, ordered_item
    assert_not_includes ordered_items, opened_item
  end

  test 'orderedItemsCount should count items with status 20' do
    initial_count = @ordr.orderedItemsCount
    menuitem = menuitems(:one)

    @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :ordered,
      ordritemprice: 10.0,
    )

    @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :opened,
      ordritemprice: 15.0,
    )

    assert_equal initial_count + 1, @ordr.orderedItemsCount
  end

  test 'preparedItems should return items with status preparing' do
    menuitem = menuitems(:one)

    prepared_item = @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :preparing,
      ordritemprice: 10.0,
    )

    ordered_item = @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :ordered,
      ordritemprice: 15.0,
    )

    prepared_items = @ordr.preparedItems
    assert_includes prepared_items, prepared_item
    assert_not_includes prepared_items, ordered_item
  end

  test 'preparedItemsCount should count items with status preparing' do
    initial_count = @ordr.preparedItemsCount
    menuitem = menuitems(:one)

    @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :preparing,
      ordritemprice: 10.0,
    )

    assert_equal initial_count + 1, @ordr.preparedItemsCount
  end

  test 'deliveredItems should return items with status 25' do
    menuitem = menuitems(:one)

    delivered_item = @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :delivered,
      ordritemprice: 10.0,
    )

    prepared_item = @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :preparing,
      ordritemprice: 15.0,
    )

    delivered_items = @ordr.deliveredItems
    assert_includes delivered_items, delivered_item
    assert_not_includes delivered_items, prepared_item
  end

  test 'deliveredItemsCount should count items with status 25' do
    initial_count = @ordr.deliveredItemsCount
    menuitem = menuitems(:one)

    @ordr.ordritems.create!(
      menuitem: menuitem,
      status: :delivered,
      ordritemprice: 10.0,
    )

    assert_equal initial_count + 1, @ordr.deliveredItemsCount
  end

  test 'totalItemsCount should count all active items' do
    # Create a new order to avoid foreign key constraints
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )
    menuitem = menuitems(:one)

    # Create items with different statuses
    ordr.ordritems.create!(menuitem: menuitem, status: :opened, ordritemprice: 10.0)
    ordr.ordritems.create!(menuitem: menuitem, status: :ordered, ordritemprice: 15.0)
    ordr.ordritems.create!(menuitem: menuitem, status: :preparing, ordritemprice: 20.0)
    ordr.ordritems.create!(menuitem: menuitem, status: :ready, ordritemprice: 25.0)
    ordr.ordritems.create!(menuitem: menuitem, status: :delivered, ordritemprice: 30.0)

    # Should count all items: opened(0), ordered(20), preparing(22), ready(24), delivered(25)
    assert_equal 5, ordr.totalItemsCount
  end

  test 'ordrDate should format created_at as dd/mm/yyyy' do
    date = Date.new(2023, 12, 25)
    @ordr.update!(created_at: date)
    assert_equal '25/12/2023', @ordr.ordrDate
  end

  test 'diners should count distinct session IDs for role 0 participants' do
    # Create test participants with different roles and session IDs
    @ordr.ordrparticipants.create!(role: 0, sessionid: 'session1')
    @ordr.ordrparticipants.create!(role: 0, sessionid: 'session2')
    @ordr.ordrparticipants.create!(role: 0, sessionid: 'session1') # Duplicate session
    @ordr.ordrparticipants.create!(role: 1, sessionid: 'session3') # Different role

    # Should count 2 distinct session IDs for role 0
    assert_equal 2, @ordr.diners
  end

  test 'runningTotal should sum all ordritem prices' do
    # Create a new order to avoid foreign key constraints
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )
    menuitem = menuitems(:one)

    ordr.ordritems.create!(menuitem: menuitem, status: :opened, ordritemprice: 10.50)
    ordr.ordritems.create!(menuitem: menuitem, status: :ordered, ordritemprice: 15.75)
    ordr.ordritems.create!(menuitem: menuitem, status: :preparing, ordritemprice: 20.25)

    assert_equal 46.50, ordr.runningTotal
  end

  test 'runningTotal should return 0 for order with no items' do
    # Create a new order without items
    ordr = Ordr.create!(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )
    assert_equal 0, ordr.runningTotal
  end

  # IdentityCache tests
  test 'should have identity cache configured' do
    assert Ordr.respond_to?(:cache_index)
    assert Ordr.respond_to?(:fetch_by_id)
    assert Ordr.respond_to?(:fetch_by_restaurant_id)
    assert Ordr.respond_to?(:fetch_by_tablesetting_id)
    assert Ordr.respond_to?(:fetch_by_menu_id)
  end

  # Dependent destroy tests
  test 'should have dependent destroy associations configured' do
    assert_equal :destroy, Ordr.reflect_on_association(:ordritems).options[:dependent]
    assert_equal :destroy, Ordr.reflect_on_association(:ordrparticipants).options[:dependent]
    assert_equal :destroy, Ordr.reflect_on_association(:ordractions).options[:dependent]
  end

  # Validation tests (if any exist)
  test 'should be valid with valid attributes' do
    ordr = Ordr.new(
      restaurant: @restaurant,
      menu: @menu,
      tablesetting: @tablesetting,
      gross: 0.0,
    )
    assert ordr.valid?
  end

  # Cache association tests
  test 'should have cached associations configured' do
    assert @ordr.respond_to?(:fetch_ordritems)
    assert @ordr.respond_to?(:fetch_ordrparticipants)
    assert @ordr.respond_to?(:fetch_ordractions)
  end
end
