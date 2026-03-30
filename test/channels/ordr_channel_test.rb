# frozen_string_literal: true

require 'test_helper'

class OrdrChannelTest < ActionCable::Channel::TestCase
  # ── Staff (authenticated user) ──────────────────────────────────────────────

  test 'staff can subscribe by order_id' do
    stub_connection current_user: users(:one), current_dining_session: nil
    subscribe order_id: ordrs(:one).id
    assert subscription.confirmed?
    assert_has_stream "ordr_#{ordrs(:one).id}_channel"
  end

  test 'staff can subscribe by slug' do
    stub_connection current_user: users(:one), current_dining_session: nil
    subscribe slug: smartmenus(:one).slug
    assert subscription.confirmed?
    assert_has_stream "ordr_#{smartmenus(:one).slug}_channel"
  end

  # ── Customer with valid dining session (qr_security_v1 ON) ─────────────────

  test 'customer with matching dining session can subscribe by order_id' do
    Flipper.enable(:qr_security_v1)
    ds = dining_sessions(:valid_session)
    ordr = ordrs(:table_one_ordr)

    stub_connection current_user: nil, current_dining_session: ds
    subscribe order_id: ordr.id
    assert subscription.confirmed?
    assert_has_stream "ordr_#{ordr.id}_channel"
  ensure
    Flipper.disable(:qr_security_v1)
  end

  test 'customer with matching dining session can subscribe by slug' do
    Flipper.enable(:qr_security_v1)
    ds = dining_sessions(:valid_session)

    stub_connection current_user: nil, current_dining_session: ds
    subscribe slug: ds.smartmenu.slug
    assert subscription.confirmed?
    assert_has_stream "ordr_#{ds.smartmenu.slug}_channel"
  ensure
    Flipper.disable(:qr_security_v1)
  end

  # ── Customer with mismatched dining session (qr_security_v1 ON) ─────────────

  test 'customer dining session for wrong restaurant is rejected for order_id' do
    Flipper.enable(:qr_security_v1)
    ds = dining_sessions(:valid_session)      # restaurant: one, tablesetting: table_one
    wrong_ordr = ordrs(:one)                  # restaurant: one, tablesetting: one — different table

    stub_connection current_user: nil, current_dining_session: ds
    subscribe order_id: wrong_ordr.id
    assert subscription.rejected?
  ensure
    Flipper.disable(:qr_security_v1)
  end

  test 'customer with no dining session is rejected for order_id' do
    Flipper.enable(:qr_security_v1)

    stub_connection current_user: nil, current_dining_session: nil
    subscribe order_id: ordrs(:table_one_ordr).id
    assert subscription.rejected?
  ensure
    Flipper.disable(:qr_security_v1)
  end

  test 'customer with no dining session is rejected for slug' do
    Flipper.enable(:qr_security_v1)

    stub_connection current_user: nil, current_dining_session: nil
    subscribe slug: smartmenus(:one).slug
    assert subscription.rejected?
  ensure
    Flipper.disable(:qr_security_v1)
  end

  # ── Legacy mode (qr_security_v1 OFF) ────────────────────────────────────────

  test 'unauthenticated customer allowed when qr_security_v1 is disabled' do
    Flipper.disable(:qr_security_v1)

    stub_connection current_user: nil, current_dining_session: nil
    subscribe order_id: ordrs(:one).id
    assert subscription.confirmed?
  end

  # ── Edge cases ───────────────────────────────────────────────────────────────

  test 'rejects when no identifier provided' do
    stub_connection current_user: users(:one), current_dining_session: nil
    subscribe({})
    assert subscription.rejected?
  end
end
