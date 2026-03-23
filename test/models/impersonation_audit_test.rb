# frozen_string_literal: true

require 'test_helper'

class ImpersonationAuditTest < ActiveSupport::TestCase
  def build_audit(overrides = {})
    now = Time.current
    ImpersonationAudit.new({
      admin_user: users(:one),
      impersonated_user: users(:two),
      started_at: now,
      expires_at: now + 1.hour,
    }.merge(overrides))
  end

  test 'is valid with all required attributes' do
    assert build_audit.valid?
  end

  test 'is invalid without started_at' do
    audit = build_audit(started_at: nil)
    assert_not audit.valid?
    assert audit.errors[:started_at].any?
  end

  test 'is invalid without expires_at' do
    audit = build_audit(expires_at: nil)
    assert_not audit.valid?
    assert audit.errors[:expires_at].any?
  end

  test 'is invalid without admin_user' do
    audit = build_audit(admin_user: nil)
    assert_not audit.valid?
  end

  test 'is invalid without impersonated_user' do
    audit = build_audit(impersonated_user: nil)
    assert_not audit.valid?
  end

  test 'belongs to admin_user and impersonated_user' do
    audit = build_audit
    assert_equal users(:one), audit.admin_user
    assert_equal users(:two), audit.impersonated_user
  end

  test 'can be saved with valid attributes' do
    audit = build_audit
    assert audit.save
  end
end
