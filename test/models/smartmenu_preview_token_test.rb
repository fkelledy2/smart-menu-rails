# frozen_string_literal: true

require 'test_helper'

class SmartmenuPreviewTokenTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # generate
  # ---------------------------------------------------------------------------

  test 'generate returns a non-blank string' do
    token = SmartmenuPreviewToken.generate(mode: :staff, menu_id: 1)
    assert token.present?
  end

  test 'generate produces different tokens for different modes' do
    staff_token = SmartmenuPreviewToken.generate(mode: :staff, menu_id: 1)
    customer_token = SmartmenuPreviewToken.generate(mode: :customer, menu_id: 1)
    assert_not_equal staff_token, customer_token
  end

  # ---------------------------------------------------------------------------
  # decode — valid tokens
  # ---------------------------------------------------------------------------

  test 'decode returns payload for a fresh staff token' do
    token   = SmartmenuPreviewToken.generate(mode: :staff, menu_id: 42)
    payload = SmartmenuPreviewToken.decode(token)

    assert_not_nil payload
    assert_equal 'staff', payload[:mode]
    assert_equal 42,      payload[:menu_id]
  end

  test 'decode returns payload for a fresh customer token' do
    token   = SmartmenuPreviewToken.generate(mode: :customer, menu_id: 7)
    payload = SmartmenuPreviewToken.decode(token)

    assert_not_nil payload
    assert_equal 'customer', payload[:mode]
    assert_equal 7,          payload[:menu_id]
  end

  # ---------------------------------------------------------------------------
  # decode — invalid / expired tokens
  # ---------------------------------------------------------------------------

  test 'decode returns nil for a blank token' do
    assert_nil SmartmenuPreviewToken.decode(nil)
    assert_nil SmartmenuPreviewToken.decode('')
  end

  test 'decode returns nil for a tampered token' do
    token = SmartmenuPreviewToken.generate(mode: :staff, menu_id: 1)
    tampered = token[0..-5] + 'XXXX'
    assert_nil SmartmenuPreviewToken.decode(tampered)
  end

  test 'decode returns nil for a completely invalid string' do
    assert_nil SmartmenuPreviewToken.decode('not-a-token-at-all')
  end

  test 'decode returns nil for an expired token' do
    token = SmartmenuPreviewToken.generate(mode: :staff, menu_id: 1)
    # Travel past the TTL
    travel_to(SmartmenuPreviewToken::TTL.from_now + 1.second) do
      assert_nil SmartmenuPreviewToken.decode(token)
    end
  end

  test 'decode returns payload for a token at the boundary (just before expiry)' do
    token = SmartmenuPreviewToken.generate(mode: :staff, menu_id: 1)
    travel_to(SmartmenuPreviewToken::TTL.from_now - 1.second) do
      assert_not_nil SmartmenuPreviewToken.decode(token)
    end
  end
end
