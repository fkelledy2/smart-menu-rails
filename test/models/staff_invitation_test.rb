# frozen_string_literal: true

require 'test_helper'

class StaffInvitationTest < ActiveSupport::TestCase
  def setup
    @restaurant = restaurants(:one)
    @inviter = users(:one)
    @acceptee = users(:two)
  end

  def build_invitation(attrs = {})
    StaffInvitation.new({
      restaurant: @restaurant,
      invited_by: @inviter,
      email: 'newstaff@example.com',
      role: :staff,
    }.merge(attrs))
  end

  # === VALIDATIONS ===

  test 'valid with required fields' do
    inv = build_invitation
    assert inv.valid?, inv.errors.full_messages.join(', ')
  end

  test 'generates token before validation' do
    inv = build_invitation
    inv.valid?
    assert_not_nil inv.token
  end

  test 'sets expiry before validation' do
    inv = build_invitation
    inv.valid?
    assert_not_nil inv.expires_at
    assert inv.expires_at > Time.current
  end

  test 'invalid without email' do
    inv = build_invitation(email: nil)
    assert_not inv.valid?
    assert inv.errors[:email].any?
  end

  test 'invalid with malformed email' do
    inv = build_invitation(email: 'not-an-email')
    assert_not inv.valid?
    assert inv.errors[:email].any?
  end

  test 'invalid without role' do
    inv = build_invitation(role: nil)
    assert_not inv.valid?
    assert inv.errors[:role].any?
  end

  # === expired? ===

  test 'expired? returns false for a fresh invitation' do
    inv = build_invitation
    inv.expires_at = 7.days.from_now
    assert_not inv.expired?
  end

  test 'expired? returns true when expires_at is in the past' do
    inv = build_invitation
    inv.expires_at = 1.second.ago
    assert inv.expired?
  end

  # === acceptable? ===

  test 'acceptable? returns true when pending and not expired' do
    inv = build_invitation
    inv.expires_at = 7.days.from_now
    inv.status = :pending
    assert inv.acceptable?
  end

  test 'acceptable? returns false when expired' do
    inv = build_invitation
    inv.expires_at = 1.second.ago
    inv.status = :pending
    assert_not inv.acceptable?
  end

  test 'acceptable? returns false when already accepted' do
    inv = build_invitation
    inv.expires_at = 7.days.from_now
    inv.status = :accepted
    assert_not inv.acceptable?
  end

  test 'acceptable? returns false when revoked' do
    inv = build_invitation
    inv.expires_at = 7.days.from_now
    inv.status = :revoked
    assert_not inv.acceptable?
  end

  # === accept! ===

  test 'accept! creates an employee and marks invitation as accepted' do
    inv = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @inviter,
      email: 'hire@example.com',
      role: :manager,
    )

    assert_difference 'Employee.count', 1 do
      result = inv.accept!(@acceptee)
      assert_kind_of Employee, result
      assert_equal 'hire@example.com', result.email
      assert result.manager?
    end

    inv.reload
    assert inv.accepted?
    assert_not_nil inv.accepted_at
  end

  test 'accept! returns false when invitation is not acceptable' do
    inv = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @inviter,
      email: 'old@example.com',
      role: :staff,
      expires_at: 1.day.ago,
    )

    assert_no_difference 'Employee.count' do
      result = inv.accept!(@acceptee)
      assert_equal false, result
    end
  end

  # === scope: active ===

  test 'active scope returns pending non-expired invitations' do
    active = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @inviter,
      email: 'active@example.com',
      role: :staff,
    )
    expired = StaffInvitation.create!(
      restaurant: @restaurant,
      invited_by: @inviter,
      email: 'expired@example.com',
      role: :staff,
      expires_at: 1.day.ago,
    )

    active_ids = StaffInvitation.active.pluck(:id)
    assert_includes active_ids, active.id
    assert_not_includes active_ids, expired.id
  end
end
