# frozen_string_literal: true

require 'test_helper'

class FloorplansHelperTest < ActionView::TestCase
  include FloorplansHelper

  # ─── floorplan_status_badge_class ────────────────────────────────────────

  test 'badge class for opened is bg-secondary' do
    assert_equal 'bg-secondary', floorplan_status_badge_class('opened')
  end

  test 'badge class for ordered is bg-primary' do
    assert_equal 'bg-primary', floorplan_status_badge_class('ordered')
  end

  test 'badge class for preparing is warning' do
    assert_includes floorplan_status_badge_class('preparing'), 'bg-warning'
  end

  test 'badge class for ready is bg-success' do
    assert_equal 'bg-success', floorplan_status_badge_class('ready')
  end

  test 'badge class for billrequested is bg-purple' do
    assert_includes floorplan_status_badge_class('billrequested'), 'bg-purple'
  end

  test 'badge class for unknown status falls back to bg-secondary' do
    assert_equal 'bg-secondary', floorplan_status_badge_class('unknown_status')
  end

  # ─── floorplan_status_label ───────────────────────────────────────────────

  test 'label for billrequested is Bill Requested' do
    assert_equal 'Bill Requested', floorplan_status_label('billrequested')
  end

  test 'label for ordered is Ordered' do
    assert_equal 'Ordered', floorplan_status_label('ordered')
  end

  test 'label for unknown status humanizes the string' do
    assert_equal 'Foo bar', floorplan_status_label('foo_bar')
  end

  # ─── floorplan_elapsed_label ─────────────────────────────────────────────

  test 'elapsed label is just now for sub-1-minute' do
    assert_equal 'just now', floorplan_elapsed_label(30.seconds.ago)
  end

  test 'elapsed label is 1 min for exactly 1 minute' do
    assert_equal '1 min', floorplan_elapsed_label(1.minute.ago)
  end

  test 'elapsed label is N min for less than 60 minutes' do
    assert_equal '14 min', floorplan_elapsed_label(14.minutes.ago)
  end

  test 'elapsed label includes hours for over 60 minutes' do
    label = floorplan_elapsed_label(90.minutes.ago)
    assert_includes label, 'h'
  end

  test 'elapsed label returns unknown for nil' do
    assert_equal 'unknown', floorplan_elapsed_label(nil)
  end

  # ─── floorplan_tile_delayed? ─────────────────────────────────────────────

  test 'preparing order over 15 min is delayed' do
    ordr = build_ordr('preparing', 20.minutes.ago)
    assert floorplan_tile_delayed?(ordr)
  end

  test 'preparing order under 15 min is not delayed' do
    ordr = build_ordr('preparing', 10.minutes.ago)
    assert_not floorplan_tile_delayed?(ordr)
  end

  test 'ready order over 15 min is delayed' do
    ordr = build_ordr('ready', 20.minutes.ago)
    assert floorplan_tile_delayed?(ordr)
  end

  test 'billrequested over 5 min is delayed' do
    ordr = build_ordr('billrequested', 6.minutes.ago)
    assert floorplan_tile_delayed?(ordr)
  end

  test 'billrequested under 5 min is not delayed' do
    ordr = build_ordr('billrequested', 3.minutes.ago)
    assert_not floorplan_tile_delayed?(ordr)
  end

  test 'opened order is never delayed' do
    ordr = build_ordr('opened', 2.hours.ago)
    assert_not floorplan_tile_delayed?(ordr)
  end

  test 'nil ordr returns false' do
    assert_not floorplan_tile_delayed?(nil)
  end

  private

  def build_ordr(status, created_at)
    ordr = Ordr.new
    ordr.define_singleton_method(:status) { status }
    ordr.define_singleton_method(:status_was) { status }
    ordr.define_singleton_method(:billrequested?) { status == 'billrequested' }
    ordr.created_at = created_at
    ordr
  end
end
