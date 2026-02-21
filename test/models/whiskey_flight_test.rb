# frozen_string_literal: true

require 'test_helper'

class WhiskeyFlightTest < ActiveSupport::TestCase
  setup do
    @menu = menus(:one)
  end

  test 'valid flight with required fields' do
    flight = WhiskeyFlight.new(
      menu: @menu,
      theme_key: 'test_flight',
      title: 'Test Flight',
      items: [{ menuitem_id: 1, position: 1, note: 'First' }],
    )
    assert flight.valid?, flight.errors.full_messages.join(', ')
  end

  test 'requires theme_key' do
    flight = WhiskeyFlight.new(menu: @menu, title: 'X', items: [{ id: 1 }])
    assert_not flight.valid?
    assert_includes flight.errors[:theme_key], "can't be blank"
  end

  test 'requires title' do
    flight = WhiskeyFlight.new(menu: @menu, theme_key: 'x', items: [{ id: 1 }])
    assert_not flight.valid?
    assert_includes flight.errors[:title], "can't be blank"
  end

  test 'requires items' do
    flight = WhiskeyFlight.new(menu: @menu, theme_key: 'x', title: 'X')
    assert_not flight.valid?
    assert_includes flight.errors[:items], "can't be blank"
  end

  test 'theme_key unique per menu' do
    WhiskeyFlight.create!(
      menu: @menu, theme_key: 'unique_key', title: 'First',
      items: [{ menuitem_id: 1, position: 1 }],
    )

    duplicate = WhiskeyFlight.new(
      menu: @menu, theme_key: 'unique_key', title: 'Second',
      items: [{ menuitem_id: 2, position: 1 }],
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:theme_key], 'has already been taken'
  end

  test 'source defaults to ai' do
    flight = WhiskeyFlight.new(
      menu: @menu, theme_key: 'ai_flight', title: 'AI Flight',
      items: [{ menuitem_id: 1, position: 1 }],
    )
    assert_equal 'ai', flight.source
  end

  test 'source can be manual' do
    flight = WhiskeyFlight.create!(
      menu: @menu, theme_key: 'manual_flight', title: 'Manual Flight',
      items: [{ menuitem_id: 1, position: 1 }],
      source: :manual,
    )
    assert flight.manual?
    assert_not flight.ai?
  end

  test 'status defaults to draft' do
    flight = WhiskeyFlight.new(
      menu: @menu, theme_key: 'draft_flight', title: 'Draft',
      items: [{ menuitem_id: 1, position: 1 }],
    )
    assert_equal 'draft', flight.status
    assert flight.draft?
  end

  test 'status transitions' do
    flight = WhiskeyFlight.create!(
      menu: @menu, theme_key: 'status_flight', title: 'Status Test',
      items: [{ menuitem_id: 1, position: 1 }],
    )
    assert flight.draft?

    flight.update!(status: :published)
    assert flight.published?

    flight.update!(status: :archived)
    assert flight.archived?
  end

  test 'visible scope returns only published flights' do
    WhiskeyFlight.create!(
      menu: @menu, theme_key: 'draft_one', title: 'Draft',
      items: [{ menuitem_id: 1, position: 1 }], status: :draft,
    )
    WhiskeyFlight.create!(
      menu: @menu, theme_key: 'pub_one', title: 'Published',
      items: [{ menuitem_id: 2, position: 1 }], status: :published,
    )
    WhiskeyFlight.create!(
      menu: @menu, theme_key: 'arch_one', title: 'Archived',
      items: [{ menuitem_id: 3, position: 1 }], status: :archived,
    )

    visible = WhiskeyFlight.visible
    assert_equal 1, visible.count
    assert_equal 'Published', visible.first.title
  end

  # ── Pricing helpers ──────────────────────────────────────────────

  test 'display_price returns custom_price when set' do
    flight = WhiskeyFlight.new(total_price: 44.0, custom_price: 40.0)
    assert_equal 40.0, flight.display_price
  end

  test 'display_price returns total_price when no custom_price' do
    flight = WhiskeyFlight.new(total_price: 44.0, custom_price: nil)
    assert_equal 44.0, flight.display_price
  end

  test 'per_dram_price divides display_price by item count' do
    flight = WhiskeyFlight.new(
      total_price: 45.0, custom_price: nil,
      items: [{ id: 1 }, { id: 2 }, { id: 3 }],
    )
    assert_equal 15.0, flight.per_dram_price
  end

  test 'per_dram_price uses custom_price when set' do
    flight = WhiskeyFlight.new(
      total_price: 45.0, custom_price: 39.0,
      items: [{ id: 1 }, { id: 2 }, { id: 3 }],
    )
    assert_equal 13.0, flight.per_dram_price
  end

  test 'per_dram_price returns nil when no items' do
    flight = WhiskeyFlight.new(total_price: 45.0, items: [])
    assert_nil flight.per_dram_price
  end

  test 'savings returns difference when custom < total' do
    flight = WhiskeyFlight.new(total_price: 44.0, custom_price: 40.0)
    assert_equal 4.0, flight.savings
  end

  test 'savings returns nil when custom >= total' do
    flight = WhiskeyFlight.new(total_price: 44.0, custom_price: 44.0)
    assert_nil flight.savings
  end

  test 'savings returns nil when no custom_price' do
    flight = WhiskeyFlight.new(total_price: 44.0, custom_price: nil)
    assert_nil flight.savings
  end
end
