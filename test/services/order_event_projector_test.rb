require 'test_helper'

class OrderEventProjectorTest < ActiveSupport::TestCase
  def setup
    @ordr = ordrs(:one)
    @menuitem = menuitems(:one)
  end

  # === item_added with quantity ===

  test 'item_added creates ordritem with quantity from payload' do
    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: {
        line_key: SecureRandom.uuid,
        menuitem_id: @menuitem.id,
        ordritemprice: 12.50,
        size_name: nil,
        qty: 3,
      },
    )

    OrderEventProjector.project!(@ordr.id)

    item = @ordr.ordritems.where(menuitem_id: @menuitem.id).order(created_at: :desc).first
    assert_not_nil item
    assert_equal 3, item.quantity
    assert_equal 12.50, item.ordritemprice
  end

  test 'item_added defaults quantity to 1 when qty absent' do
    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: {
        line_key: SecureRandom.uuid,
        menuitem_id: @menuitem.id,
        ordritemprice: 8.00,
        size_name: nil,
      },
    )

    OrderEventProjector.project!(@ordr.id)

    item = @ordr.ordritems.where(menuitem_id: @menuitem.id).order(created_at: :desc).first
    assert_not_nil item
    assert_equal 1, item.quantity
  end

  test 'item_added merges into existing opened row with same menuitem and size' do
    existing = @ordr.ordritems.create!(
      menuitem: @menuitem,
      ordritemprice: 10.00,
      status: :opened,
      quantity: 2,
      size_name: nil,
    )

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: {
        line_key: SecureRandom.uuid,
        menuitem_id: @menuitem.id,
        ordritemprice: 10.00,
        size_name: nil,
        qty: 3,
      },
    )

    count_before = @ordr.ordritems.count
    OrderEventProjector.project!(@ordr.id)

    existing.reload
    assert_equal 5, existing.quantity
    assert_equal count_before, @ordr.ordritems.reload.count, 'Should not create a new row'
  end

  test 'item_added does not merge when size_name differs' do
    existing = @ordr.ordritems.create!(
      menuitem: @menuitem,
      ordritemprice: 10.00,
      status: :opened,
      quantity: 1,
      size_name: 'Small',
    )

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: {
        line_key: SecureRandom.uuid,
        menuitem_id: @menuitem.id,
        ordritemprice: 14.00,
        size_name: 'Large',
        qty: 2,
      },
    )

    count_before = @ordr.ordritems.count
    OrderEventProjector.project!(@ordr.id)

    assert_equal count_before + 1, @ordr.ordritems.reload.count, 'Should create a new row for different size'
    existing.reload
    assert_equal 1, existing.quantity, 'Existing row should be unchanged'
  end

  test 'item_added clamps merged quantity at 99' do
    existing = @ordr.ordritems.create!(
      menuitem: @menuitem,
      ordritemprice: 10.00,
      status: :opened,
      quantity: 95,
      size_name: nil,
    )

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: {
        line_key: SecureRandom.uuid,
        menuitem_id: @menuitem.id,
        ordritemprice: 10.00,
        size_name: nil,
        qty: 10,
      },
    )

    OrderEventProjector.project!(@ordr.id)

    existing.reload
    assert_equal 99, existing.quantity
  end

  test 'item_added does not merge into non-opened rows' do
    existing = @ordr.ordritems.create!(
      menuitem: @menuitem,
      ordritemprice: 10.00,
      status: :ordered,
      quantity: 2,
      size_name: nil,
    )

    OrderEvent.emit!(
      ordr: @ordr,
      event_type: 'item_added',
      entity_type: 'Ordritem',
      source: 'test',
      payload: {
        line_key: SecureRandom.uuid,
        menuitem_id: @menuitem.id,
        ordritemprice: 10.00,
        size_name: nil,
        qty: 1,
      },
    )

    count_before = @ordr.ordritems.count
    OrderEventProjector.project!(@ordr.id)

    assert_equal count_before + 1, @ordr.ordritems.reload.count, 'Should create new row since existing is ordered, not opened'
    existing.reload
    assert_equal 2, existing.quantity, 'Ordered row should be unchanged'
  end
end
