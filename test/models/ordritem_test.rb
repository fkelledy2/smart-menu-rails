require 'test_helper'

class OrdritemTest < ActiveSupport::TestCase
  def setup
    @ordritem = ordritems(:one)
    @ordr = ordrs(:one)
    @menuitem = menuitems(:one)
  end

  # Association tests
  test 'should belong to ordr' do
    assert_respond_to @ordritem, :ordr
    assert_not_nil @ordritem.ordr
  end

  test 'should belong to menuitem' do
    assert_respond_to @ordritem, :menuitem
    assert_not_nil @ordritem.menuitem
  end

  test 'should have one ordrparticipant' do
    assert_respond_to @ordritem, :ordrparticipant
  end

  # Enum tests
  test 'should have status enum' do
    assert_respond_to @ordritem, :status
    assert_respond_to @ordritem, :added?
    assert_respond_to @ordritem, :removed?
    assert_respond_to @ordritem, :ordered?
    assert_respond_to @ordritem, :prepared?
    assert_respond_to @ordritem, :delivered?
  end

  test 'should set status correctly' do
    @ordritem.status = :added
    assert @ordritem.added?
    assert_not @ordritem.removed?
    assert_not @ordritem.ordered?
    assert_not @ordritem.prepared?
    assert_not @ordritem.delivered?

    @ordritem.status = :removed
    assert @ordritem.removed?
    assert_not @ordritem.added?
    assert_not @ordritem.ordered?
    assert_not @ordritem.prepared?
    assert_not @ordritem.delivered?

    @ordritem.status = :ordered
    assert @ordritem.ordered?
    assert_not @ordritem.added?
    assert_not @ordritem.removed?
    assert_not @ordritem.prepared?
    assert_not @ordritem.delivered?

    @ordritem.status = :prepared
    assert @ordritem.prepared?
    assert_not @ordritem.added?
    assert_not @ordritem.removed?
    assert_not @ordritem.ordered?
    assert_not @ordritem.delivered?

    @ordritem.status = :delivered
    assert @ordritem.delivered?
    assert_not @ordritem.added?
    assert_not @ordritem.removed?
    assert_not @ordritem.ordered?
    assert_not @ordritem.prepared?
  end

  # Validation tests
  test 'should be valid with valid attributes' do
    ordritem = Ordritem.new(
      ordr: @ordr,
      menuitem: @menuitem,
      status: :added,
      ordritemprice: 10.50,
    )
    assert ordritem.valid?
  end

  test 'should require ordr' do
    ordritem = Ordritem.new(
      menuitem: @menuitem,
      status: :added,
      ordritemprice: 10.50,
    )
    assert_not ordritem.valid?
    assert_includes ordritem.errors[:ordr], 'must exist'
  end

  test 'should require menuitem' do
    ordritem = Ordritem.new(
      ordr: @ordr,
      status: :added,
      ordritemprice: 10.50,
    )
    assert_not ordritem.valid?
    assert_includes ordritem.errors[:menuitem], 'must exist'
  end

  # Business logic tests
  test 'should handle price calculations' do
    @ordritem.update!(ordritemprice: 15.75)
    assert_equal 15.75, @ordritem.ordritemprice
  end

  test 'should handle zero price' do
    @ordritem.update!(ordritemprice: 0.0)
    assert_equal 0.0, @ordritem.ordritemprice
  end

  test 'should handle negative price' do
    @ordritem.update!(ordritemprice: -5.0)
    assert_equal(-5.0, @ordritem.ordritemprice)
  end

  # Status workflow tests
  test 'should progress through typical order workflow' do
    ordritem = Ordritem.create!(
      ordr: @ordr,
      menuitem: @menuitem,
      status: :added,
      ordritemprice: 12.50,
    )

    # Start as added
    assert ordritem.added?

    # Move to ordered
    ordritem.update!(status: :ordered)
    assert ordritem.ordered?

    # Move to prepared
    ordritem.update!(status: :prepared)
    assert ordritem.prepared?

    # Move to delivered
    ordritem.update!(status: :delivered)
    assert ordritem.delivered?
  end

  test 'should handle removal workflow' do
    ordritem = Ordritem.create!(
      ordr: @ordr,
      menuitem: @menuitem,
      status: :added,
      ordritemprice: 12.50,
    )

    # Start as added
    assert ordritem.added?

    # Can be removed
    ordritem.update!(status: :removed)
    assert ordritem.removed?
  end

  # IdentityCache tests
  test 'should have identity cache configured' do
    assert Ordritem.respond_to?(:cache_index)
    assert Ordritem.respond_to?(:fetch_by_id)
    assert Ordritem.respond_to?(:fetch_by_ordr_id)
    assert Ordritem.respond_to?(:fetch_by_menuitem_id)
  end

  # Cache association tests
  test 'should have cached associations configured' do
    assert @ordritem.respond_to?(:fetch_ordr)
    assert @ordritem.respond_to?(:fetch_menuitem)
    assert @ordritem.respond_to?(:fetch_ordrparticipant)
  end

  # Edge case tests
  test 'should handle very large prices' do
    @ordritem.update!(ordritemprice: 999_999.99)
    assert_equal 999_999.99, @ordritem.ordritemprice
  end

  test 'should handle very small prices' do
    @ordritem.update!(ordritemprice: 0.01)
    assert_equal 0.01, @ordritem.ordritemprice
  end

  # Association integrity tests
  test 'should maintain association with ordr' do
    original_ordr = @ordritem.ordr
    assert_equal original_ordr.id, @ordritem.ordr_id
  end

  test 'should maintain association with menuitem' do
    original_menuitem = @ordritem.menuitem
    assert_equal original_menuitem.id, @ordritem.menuitem_id
  end

  # Status value tests
  test 'should have correct enum values' do
    assert_equal 0, Ordritem.statuses[:added]
    assert_equal 10, Ordritem.statuses[:removed]
    assert_equal 20, Ordritem.statuses[:ordered]
    assert_equal 30, Ordritem.statuses[:prepared]
    assert_equal 40, Ordritem.statuses[:delivered]
  end
end
